#require 'models_helper'
#require 'application_defs'
#require 'match_state'
#require 'game_definition'
#require 'player_manager'

# A proxy player for the web poker application.
class WebApplicationPlayerProxy
   include ModelsHelper
   include ApplicationDefs
   
   #@todo
   attr_reader :proxy_bot
   
   #@todo
   attr_reader :game_definition
   
   #@todo
   attr_reader :max_number_of_hands
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [GameDefinition] game_definition The definition of the game.
   # @param [Integer] number_of_hands
   def initialize(dealer_information, game_definition, number_of_hands)
      @proxy_bot = ProxyBot.new dealer_information
      @game_definition = game_definition
      @max_number_of_hands = number_of_hands
   end
   
   # Interface to game logic ##################################################
   
   # Player state mutation methods --------------------------------------------
   
   # (see PlayerManager#update_state!)
   def update_state!(new_match_state)
      log "update_state!: #{new_match_state}"
      
      @player_manager.update_state! new_match_state
      update! new_match_state
   end
   
   # (see PlayerManager#start_new_hand!)
   def start_new_hand!(initial_match_state_for_new_hand)
      log "start_new_hand!: #{initial_match_state_for_new_hand}"
      
      @player_manager.start_new_hand! initial_match_state_for_new_hand
      update! initial_match_state_for_new_hand
   end
   
   
   # Player action interface -------------------------------------------------- 
   
   # @return [String] Matchstate string corresponding to a call or check action.
   def make_call_or_check_action
      "#{@match_state_string}:c"
   end
     
   # @return [String] Matchstate string corresponding to a fold action.
   def make_fold_action
      "#{@match_state_string}:f"
   end
   
   # @return [String] Matchstate string corresponding to a raise or bet action.
   def make_raise_or_bet_action
      "#{@match_state_string}:r"
   end
   
   
   # Player state retrieval methods -------------------------------------------
   
   # (see PlayerManager#player_with_the_dealer_button)
   def player_with_the_dealer_button
      player = @player_manager.player_with_the_dealer_button
      
      log "player_with_the_dealer_button: name: #{player.name}"
      
      player
   end
   
   # (see PlayerManager#player_who_submitted_big_blind)
   def player_who_submitted_big_blind
      player = @player_manager.player_who_submitted_big_blind
      
      log "player_who_submitted_big_blind: name: #{player.name}"
      
      player
   end
   
   # (see PlayerManager#player_who_submitted_small_blind)
   def player_who_submitted_small_blind
      player = @player_manager.player_who_submitted_small_blind
      
      log "player_who_submitted_small_blind: name: #{player.name}"
      
      player
   end
   
   # (see PlayerManager#player_whose_turn_is_next)
   def player_whose_turn_is_next
      player = @player_manager.player_whose_turn_is_next
      
      log "player_whose_turn_is_next: name: #{player.name}"
      
      player
   end
   
   # (see PlayerManager#player_who_acted_last)
   def player_who_acted_last
      log 'player_who_acted_last'
      
      player = @player_manager.player_who_acted_last
      
      log "player_who_acted_last: name: #{player.name}" if player
      
      player
   end
   
   # (see PlayerManager#pot_size)
   def pot_size
      log 'pot_size'
      
      @player_manager.pot_size
   end
   
   # (see PlayerManager#list_of_player_stacks)
   def list_of_player_stacks
      log 'list_of_player_stacks'
      
      @player_manager.list_of_player_stacks
   end
   
   # (see PlayerManager#users_hole_cards)
   def users_hole_cards
      @player_manager.users_hole_cards
   end
   
   # (see PlayerManager#list_of_opponents_hole_cards)
   def list_of_opponents_hole_cards
      @player_manager.list_of_opponents_hole_cards
   end
   
   # (see PlayerManager#list_of_betting_actions)
   def list_of_betting_actions
      @player_manager.list_of_betting_actions
   end
   
   # (see PlayerManager#list_of_board_cards)
   def list_of_board_cards
      @player_manager.list_of_board_cards
   end
   
   # (see PlayerManager#hand_number)
   def hand_number
      @player_manager.hand_number
   end
   
   # (see PlayerManager#users_position)
   def users_position
      @player_manager.users_position
   end
   
   # (see PlayerManager#last_action)
   def last_action
      @player_manager.last_action
   end
   
   # (see PlayerManager#legal_actions)
   def legal_actions
      @player_manager.legal_actions
   end
   
   # (see PlayerManager#round)
   def round
      @player_manager.round
   end
   
   # (see PlayerManager#active_players)
   def active_players
      @player_manager.active_players
   end
   
   # (see PlayerManager#users_turn_to_act?)
   def users_turn_to_act?
      log "users_turn_to_act?"
      
      @player_manager.users_turn_to_act?
   end
   
   # (see PlayerManager#hand_ended?)
   def hand_ended?
      @player_manager.hand_ended?
   end
   
   # (see PlayerManager#match_ended?)
   def match_ended?
      @player_manager.match_ended? 
   end
   
   # (see PlayerManager#big_blind)   
   def big_blind
      @player_manager.big_blind
   end
   
   # (see PlayerManager#small_blind)
   def small_blind
      @player_manager.small_blind
   end
   
   # (see PlayerManager#raise_size_in_this_round)
   def raise_size_in_this_round
      @player_manager.raise_size_in_this_round
   end
   
   # (see PlayerManager#list_of_player_chip_balances)
   def list_of_player_chip_balances
      @player_manager.list_of_player_chip_balances
   end
   
   # (see PlayerManager#max_number_of_hands)
   def max_number_of_hands
      @player_manager.max_number_of_hands
   end
   
   
   # All following methods are private ########################################
   private
   
   def string_for_taking_action(action)
      expected_string = "#{@match_state}:" + action + TERMINATION_STRING
   end
   
   def update!(match_state)
      @match_state_string = match_state.to_s
   end
   
   # @todo From ProxyBot ############
   # @return [MatchstateString] The current match state string.
   attr_reader :match_state_string
   
   # @return [Integer] The position relative to the dealer that is next to act.
   attr_reader :position_relative_to_dealer_next_to_act
   
   # @return [Integer] The position relative to the dealer that acted last.
   attr_reader :position_relative_to_dealer_acted_last
   
   # @return [Integer] The maximum number of hands in the current match.
   attr_reader :max_number_of_hands
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   def initialize(dealer_information)
      @dealer_communicator = AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name
   end
   
   # @param [Symbol] action The action to be sent.
   # @param [#to_s] modifier A modifier that should be associated with the
   #  +action+ before it is sent.
   # @raise (see ActionSender#send_action)
   def send_action(action, modifier = nil)
      ActionSender.send_action @dealer_communicator, @match_state_string, action, modifier
   end
   
   # @see MatchstateStringReceiver#receive_match_state_string
   def receive_match_state_string
      # @todo Not sure if I need to keep track of this
      @last_round = @match_state_string.round if @match_state_string
      
      #@position_relative_to_dealer_acted_last = @position_relative_to_dealer_next_to_act if @position_relative_to_dealer_next_to_act
      
      @match_state_string = MatchstateStringReceiver.receive_matchstate_string @dealer_communicator
      
      #find_position_relative_to_dealer_next_to_act!
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?      
      less_than_two_active_players? || reached_showdown?
   end
   
   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?      
      #users_turn_to_act = @position_relative_to_dealer_next_to_act == @match_state_string.position_relative_to_dealer
      #
      ## Check if the match has ended
      #users_turn_to_act &= !match_ended?
      #
      #users_turn_to_act
   end
   
   private
   
   #@todo This may not work if the dealer just immediately sends the next match state after a fold and it definitely doesn't work in 3-player
   def less_than_two_active_players?
      'f' == @match_state_string.last_action
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   # @todo make this more general; this only works for two-splayer right now.
   def opponents_cards_visible?
      are_visible = 1 == @match_state_string.list_of_opponents_hole_cards.length
   end
   
   #def find_position_relative_to_dealer_next_to_act!
   #   number_of_actions_in_current_round = @match_state.number_of_actions_in_current_round
   #   first_position_in_current_round = @game_definition.first_player_position_in_each_round[round]-1
   #   
   #   @position_relative_to_dealer_next_to_act = (first_position_in_current_round + number_of_actions_in_current_round) % number_of_active_players
   #end
end
