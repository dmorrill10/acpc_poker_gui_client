
# Local modules
require File.expand_path('../../application_defs', __FILE__)

# Local classes
require File.expand_path('../../bots/proxy_bot/proxy_bot', __FILE__)
require File.expand_path('../../bots/proxy_bot/domain_types/*', __FILE__)

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
   include ApplicationDefs
   
   # @param [String] match_id The ID of the match in which this player is participating.
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [String] game_definition_file_name The name of the file containing the definition of the game, of which, this match is an instance.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(match_id, dealer_information, game_definition, number_of_hands=1)
      @proxy_bot = ProxyBot.new dealer_information
      @game_definition = GameDefinition.new game_definition
      @max_number_of_hands = number_of_hands
      
      start_new_hand!
   end
   
   # Player action interface
   # @todo Fix all of these
   def play!(action, modifier=nil)
      @proxy_bot.send_action action, modifier
      
      update_match_state!
      
      # @todo Need to do other stuff?
   end
   
   private
   
   # (see PlayerManager#start_new_hand!)
   def start_new_hand!
      update_match_state!
      
      reset_players! initial_match_state_for_new_hand
      
      update! initial_match_state_for_new_hand
   end
   
   def update_match_state!
      remember_values_from_last_round!
      
      @match_state = next_match_state
      
      update_database!
   end
   
   # @todo Still works?
   def assign_hole_cards_to_opponents!
      local_list_of_hole_cards = @match_state.list_of_hole_card_sets

      list_of_opponent_players.each do |opponent|
         opponent.hole_cards = local_list_of_hole_cards[opponent.position_relative_to_dealer] unless opponent.has_folded
      end
   end
   
   # @todo Still works?
   def evaluate_end_of_hand!
      local_active_players = active_players
      
      # If there is only one active player, that player has won the pot
      if 1 == local_active_players.length
         local_active_players[0].take_winnings! pot_size
      else
         evaluate_showdown!
      end
   end
   
   # @todo Doesn't still work. Need to use the Pot to manipulate chips rather than players.
   def update_state_of_players!
      last_player_to_act = @players[player_who_acted_last_index]
      case last_action
         when ACTION_TYPES[:call]
            last_player_to_act.call_current_wager!
         when ACTION_TYPES[:fold]
            last_player_to_act.has_folded = true
         when ACTION_TYPES[:raise]            
            # TODO this will become a problem during no-limit but will be fine for limit
            last_player_to_act.call_current_wager!
            
            raise_size = raise_size_in_this_round
            
            last_player_to_act.place_wager! raise_size
            
            players_who_did_not_act_last = @players.reject { |player| player.position_relative_to_dealer == @position_relative_to_dealer_acted_last }
            players_who_did_not_act_last.map { |player| player.current_wager_faced += raise_size }
      end
      if hand_ended?
         evaluate_end_of_hand!
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
      proxy_bot.receive_match_state_string
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
      are_visible = (list_of_opponents_hole_cards.length > 0)
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
      @match_state_string.position_relative_to_dealer
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
   
   def reset_players!(match_state)
      @players.each_index do |i|
         @players[i].is_all_in = false
         @players[i].has_folded = false
         @players[i].current_wager_faced = big_blind
         @players[i].stack = @game_definition.list_of_player_stacks[i] # TODO if @is_doyles_game
      end
      
      adjust_big_blind_players_stack
      adjust_small_blind_players_stack
      
      user = user_player
      user.hole_cards = match_state.users_hole_cards
   end
   
   def list_of_opponent_players
      local_list_of_players = @players.dup
      local_list_of_players.delete_at USERS_INDEX
      local_list_of_players
   end
   
   def adjust_big_blind_players_stack
      big_blind_player = player_who_submitted_big_blind
      big_blind_player.call_current_wager!
   end
   
   def adjust_small_blind_players_stack
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
