
# Local modules
require File.expand_path('../../application_defs', __FILE__)

# Local classes
require File.expand_path('../../bots/proxy_bot/proxy_bot', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/board_cards', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/card', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/chip_stack', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/game_definition', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/hand', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/matchstate_string', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/player', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/side_pot', __FILE__)

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
   include ApplicationDefs
   
   # @param [String] match_id The ID of the match in which this player is participating.
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [String] game_definition_file_name The name of the file containing the definition of the game, of which, this match is an instance.
   # @param [String] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(match_id, dealer_information, game_definition, player_names='user, p2', number_of_hands=1)
      @match_id = match_id
      @proxy_bot = ProxyBot.new dealer_information
      @game_definition = GameDefinition.new game_definition
      @max_number_of_hands = number_of_hands
      
      @match_state = next_match_state
      
      @players = create_players player_names
      
      assign_users_cards!
      
      # @todo Check that this actually works
      @pot = create_new_pot
      
      update_database!
      
      update_match_state! unless users_turn_to_act?
   end
   
   # Player action interface
   def play!(action, modifier=nil)
      puts "play!: action: #{action}, modifier: #{modifier}"
      
      @proxy_bot.send_action action, modifier
      
      puts "play!: action sent, update_match_state!"
      
      update_match_state!
   end
   
   private
   
   def create_players(player_names)
      list_of_player_names = player_names.split(/,?\s+/)
      
      # @todo Ensure that list_of_player_names.length == number_of_players
      
      # The array of players is built so that it's centered on the user.
      # The user is at index USERS_INDEX = 0, the player to the user's immediate left is
      # at index 1, etc.
      players = []
      number_of_players.times do |player_index|
         name = list_of_player_names[player_index]
         seat = player_index         
         my_position_relative_to_dealer = (position_relative_to_dealer + player_index) % number_of_players
         position_relative_to_user = users_position_relative_to_user - player_index
         stack = ChipStack.new @game_definition.list_of_player_stacks[player_index]
         
         players << Player.new(name, seat, my_position_relative_to_dealer, position_relative_to_user, stack)
      end
      
      players
   end
      
   def update_match_state!      
      remember_values_from_last_round!
      @match_state = next_match_state
      if first_state_of_the_first_round?
         start_new_hand!
      else
         update_state_of_players!
         evaluate_end_of_hand! if hand_ended?
      end
      update_database!
      update_match_state! unless users_turn_to_act?
   end
   
   # (see PlayerManager#start_new_hand!)
   def start_new_hand!      
      reset_players!
   end
   
   def reset_players!
      @players.each_index do |i|
         @players[i].is_all_in = false
         @players[i].has_folded = false
         @players[i].stack = ChipStack.new @game_definition.list_of_player_stacks[i] # TODO if @is_doyles_game
      end
      
      @pot = create_new_pot
      
      assign_users_cards!
   end
   
   def create_new_pot
      pot = SidePot.new player_who_submitted_big_blind, big_blind
      pot.contribute! player_who_submitted_small_blind, small_blind
      pot
   end

   # @todo check if this works.
   def update_database!
      # Create a new database record with the current match state information
      # Insert the ID of the next record into the last database record, creating a linked list for the web app. to follow.
      previous_match_record = Match.find(@match_id)
      
      puts "update_database!: previous_match_record.id: #{previous_match_record.id}"
      
      # Initialize a match
      next_match_record = Match.new(state_string: @match_state.to_s, pot: [pot_size], is_match_ended: match_ended?, is_users_turn_to_act: users_turn_to_act?)
      unless next_match_record.save
         raise "Unable to save new match record"
         # @todo Raise error
      else
         @match_id = next_match_record.id
         
         # @todo Raise error unless
         unless previous_match_record.update_attributes!(next_match_id: next_match_record.id)
            raise "Unable to save update 'next_match_id' attribute of match with ID: #{previous_match_record.id}"
         end
      end
   end
   
   # @todo Is round zero indexed?
   def first_state_of_the_first_round?
      0 == round && 0 == number_of_actions_in_current_round
   end
   
   def assign_users_cards!
      user = user_player
      user.hole_cards = users_hole_cards
   end
   
   def assign_hole_cards_to_opponents!
      list_of_opponent_players.each do |opponent|
         opponent.hole_cards = @match_state.list_of_hole_card_hands[opponent.position_relative_to_dealer] unless opponent.has_folded
      end
   end
   
   def evaluate_end_of_hand!
      assign_hole_cards_to_opponents!
      @pot.distribute_chips!
   end
   
   def update_state_of_players!
      last_player_to_act = @players[player_who_acted_last_index]
      case last_action
         when ACTION_TYPES[:call]
            @pot.take_call! last_player_to_act
         when ACTION_TYPES[:fold]
            last_player_to_act.has_folded = true
         when ACTION_TYPES[:raise]
            @pot.take_raise! last_player_to_act, raise_size_in_this_round
      end
   end
   
   def remember_values_from_last_round!
      if @match_state
         # @todo Not sure if I need to keep track of this
         @last_round = round 
         @position_relative_to_dealer_acted_last = position_relative_to_dealer_next_to_act
         @last_match_state = @match_state
      end
   end
   
   def next_match_state
      @proxy_bot.receive_match_state_string
   end 
   
   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?      
      users_turn_to_act = position_relative_to_dealer_next_to_act == position_relative_to_dealer
      
      users_turn_to_act &= !match_ended?
   end
   
   # Convienence methods for retrieving particular players
   
   # (see GameCore#player_who_submitted_small_blind)
   def player_who_submitted_small_blind      
      @players[player_who_submitted_small_blind_index]
   end
   
   # (see GameCore#player_whose_turn_is_next)
   def player_whose_turn_is_next      
      @players[player_whose_turn_is_next_index]
   end
   
   # @return The +Player+ who acted last or nil if none have played yet.
   def player_who_acted_last
      return nil unless @last_match_state
      @players[player_who_acted_last_index]
   end
   
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button      
      @players.each { |player| return player if dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
   
   # (see GameCore#player_who_submitted_big_blind)
   def player_who_submitted_big_blind      
      @players[player_who_submitted_big_blind_index]
   end
   
   def user_player
      @players[USERS_INDEX]
   end
   
   # @return [Array] The players in the game still currently active.
   def active_players
      @players.select { |player| player.is_active? }
   end
   
   # Methods for retrieving the indices of particular players
   
   def player_with_the_dealer_button_index
      @players.index { |player| dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
 
   def player_who_submitted_big_blind_index
      big_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_big_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_big_blind] end
      index = @players.index do |player|
         player.position_relative_to_dealer == big_blind_position
      end
      
      index
   end
   
   def player_who_submitted_small_blind_index
      small_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_small_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_small_blind] end
      @players.index { |player| player.position_relative_to_dealer == small_blind_position }
   end
   
   def player_whose_turn_is_next_index
      @players.index { |player| player.position_relative_to_dealer == position_relative_to_dealer_next_to_act }
   end
   
   def player_who_acted_last_index
      @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_acted_last }
   end
   
   # Convenience game logic methods
   
   # @return [Boolean] +true+ if the current hand is the last in the match.
   def last_hand?
      @max_number_of_hands - 1 == hand_number
   end
   
   #@todo This may not work if the dealer just immediately sends the next match state after a fold and it definitely doesn't work in 3-player
   def less_than_two_active_players?
      'f' == last_action
   end
      
   # @return [Integer] The position relative to the dealer that is next to act.
   # @todo I think this will not work outside of two player.
   def position_relative_to_dealer_next_to_act      
      (first_player_position_in_current_round - 1 + number_of_actions_in_current_round) % number_of_active_players
   end
   
   def users_position_relative_to_user
      number_of_players - 1
   end
   
   # (see GameCore#list_of_player_stacks)
   def list_of_player_stacks
      @players.map { |player| player.stack }
   end
   
   def number_of_active_players
      active_players.length
   end
   
   def is_reverse_blinds?
      2 == @game_definition.number_of_players
   end
   
   def last_round?
      number_of_rounds - 1 == round 
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?      
      less_than_two_active_players? || reached_showdown?
   end
   
   def less_than_two_active_players?      
      active_players.length < 2
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   # @return [Boolean] +true+ if any opponents cards are visible, +false+ otherwise.
   def opponents_cards_visible?
      are_visible = (list_of_opponents_hole_cards.length > 0 && !list_of_opponents_hole_cards[0].empty?)
   end
   
   # @return [Boolean] +true+ if the match has ended, +false+ otherwise.
   def match_ended?      
      hand_ended? && last_hand?
   end
   
   # Wrappers for methods found in instance variables.
   
   # @see GameDefinition#number_of_rounds
   def number_of_rounds
      @game_definition.number_of_rounds
   end
   
   # @see MatchstateString#last_action
   def last_action
      @match_state.last_action
   end
   
   # @see MatchstateString#round
   def round
      @match_state.round
   end
   
   # @see MatchstateString#number_of_actions_in_current_round
   def number_of_actions_in_current_round
      @match_state.number_of_actions_in_current_round
   end
   
   # @see GameDefinition#first_player_position_in_each_round
   def first_player_position_in_each_round
      @game_definition.first_player_position_in_each_round
   end
   
   # @see GameDefinition#number_of_players
   def number_of_players
      @game_definition.number_of_players
   end
   
   # @return [Integer] The first player position in the current round.
   def first_player_position_in_current_round
      first_player_position_in_each_round[round]
   end
   
   # @see MatchstateString#list_of_opponents_hole_cards
   def list_of_opponents_hole_cards
      @match_state.list_of_opponents_hole_cards
   end
   
   # @see MatchstateString#position_relative_to_dealer
   def position_relative_to_dealer
      @match_state.position_relative_to_dealer
   end
   
   # @see MatchstateString#list_of_betting_actions
   def list_of_betting_actions
      @match_state.list_of_betting_actions
   end
   
   # @see MatchstateString#board_cards
   def board_cards
      @match_state.board_cards
   end
 
   # #see MatchstateString#hand_number
   def hand_number
      @match_state.hand_number
   end
   
   # @see MatchstateString#position_relative_to_dealer
   def users_position
      @match_state.position_relative_to_dealer
   end
   
   def users_hole_cards
      @match_state.users_hole_cards
   end
   
   # @see Pot#value
   def pot_size      
      @pot.value
   end
   
   # @return [Array] An array of legal actions for the currently acting player.
   def legal_actions
   end
   
   
   
   # @todo Integrate these methods into this class
   
   def dealer_position_relative_to_dealer
      @game_definition.number_of_players - 1
   end
   
   def list_of_opponent_players
      local_list_of_players = @players.dup
      local_list_of_players.delete_at USERS_INDEX
      local_list_of_players
   end
   
   def take_small_blind!
      @pot.take
      small_blind_player = player_who_submitted_small_blind
      small_blind_player.current_wager_faced = small_blind
      small_blind_player.call_current_wager!
      small_blind_player.current_wager_faced = big_blind - small_blind
   end

   # (see GameDefinition#big_blind)   
   def big_blind
      @game_definition.big_blind
   end
   
   # (see GameDefinition#small_blind)
   def small_blind
      @game_definition.small_blind
   end
   
   # return [Integer] The minimum raise amount in the current round.
   def raise_size_in_this_round
      @game_definition.raise_size_in_each_round[round]
   end
   
   # return [Integer] The list containing each player's current chip balance.
   def list_of_player_chip_balances
      @players.map { |player| player.chip_balance }
   end
   
   # return [Array] The list of players that have not yet folded.
   def list_of_players_who_have_not_folded
      @players.reject { |player| player.has_folded }
   end
   
   # return [Array] The list of players who have folded.
   def list_of_players_who_have_folded
      @players.select { |player| player.has_folded }
   end
end
