require 'models_helper'
require 'application_defs'

require 'match_state'
require 'game_definition'
require 'game_state'
require 'dealer_communication'
require 'player'

# Class to create all the objects that deal with game logic.
class GameCore                 
   include ModelsHelper
   include ApplicationDefs
   
   # TODO should I do something with the random seed

   # @param [String] game_definition_file_name The name of the game definition
   #     file that is to be used to define the parameters of the game.
   # @param [AcpcDealerCommunicator] dealer_communication_service A service that
   #     allows communication to and from the dealer.
   def initialize(match_name, game_definition_file_name, number_of_hands,
                  random_seed, player_names, dealer_communication_service)
      log "initialize"
      
      @dealer_communication_service = dealer_communication_service
      
      result = catch(:incomplete_match_state) do next_match_state end
      if result.kind_of?(MatchstateString) then @match_state = result else throw :game_core_error, result end
      
      result = catch(:game_definition_error) do GameDefinition.new(game_definition_file_name) end
      if result.kind_of?(GameDefinition) then @game_definition = result else throw :game_core_error, result end
      
      list_of_player_names = player_names.split(/,?\s+/)
      
      # The array of players is built so that it's centered on the user.
      # The user is at index USERS_INDEX = 0, the player to the user's immediate left is
      # at index 1, etc.
      @players = []
      @game_definition.number_of_players.times do |player_index|
         name = list_of_player_names[player_index]
         seat = player_index
         position_relative_to_dealer = (@match_state.position_relative_to_dealer + player_index) % @game_definition.number_of_players
         position_relative_to_user = users_position_relative_to_user - player_index
         stack = @game_definition.list_of_player_stacks[player_index]
         
         @players << Player.new(name, seat, position_relative_to_dealer, position_relative_to_user, stack)
      end
      
      @player_manager = PlayerManager.new(@game_definition, @players, number_of_hands)
      
      @game_state = GameState.new(@game_definition, @player_manager, match_name)
      
      @game_state.start_new_hand! @match_state
      
      log 'initialize: exiting cleanly'
   end
   
   # Interface to game logic ###################################################
  
  # Game state mutation methods -----------------------------------------------
  
   # Updates the match and game states managed by this instance.
   # @raise 'game_core_error'
   def update_state!
      log "update_state!"
      
      if @dealer_communication_service.ready_to_read?
         result = catch(:incomplete_match_state) do next_match_state end
         if result.kind_of?(MatchstateString) then @match_state = result else throw :game_core_error, result end
      
         @game_state.update_state! @match_state
      end
      
      true
   end
   
   # Set internal state so that it's ready to start a new hand
   def start_new_hand!
      #TODO check if this actually works
      log 'start_new_hand!'
      #do_or_throw_game_core_error {@match_state = @dealer_communication_service.gets}
      
      if @dealer_communication_service.ready_to_read?
         result = catch(:incomplete_match_state) do next_match_state end
         if result.kind_of?(MatchstateString) then @match_state = result else throw :game_core_error, result end
      
         @game_state.start_new_hand! @match_state
      end
   end
  
  
   # Player action interface --------------------------------------------------- 
  
   # Sends a bet action to the dealer.
   # @raise +:game_core_error+
   def make_bet_action
      make_raise_action
   end
   
   # Sends a call action to the dealer.
   # @raise (see GameCore#make_bet_action)
   def make_call_action
      log 'make_call_action'
      
      if @dealer_communication_service.ready_to_write?
         call_action = @game_state.make_call_or_check_action
         
         begin
            log "make_call_action: call_action: #{call_action}"
            
            @dealer_communication_service.puts(call_action)
         rescue => dealer_communication_error
            log "make_call_action: dealer_communication_error: #{dealer_communication_error.message}"
            
            throw :game_core_error, dealer_communication_error.message
         end
      end
      
      true
   end
   
   # Sends a check action to the dealer.
   # @raise (see GameCore#make_bet_action)
   def make_check_action
      make_call_action
   end
  
   # Sends a fold action to the dealer.
   # @raise (see GameCore#make_bet_action)
   def make_fold_action
      log 'make_fold_action'
      
      if @dealer_communication_service.ready_to_write?
         fold_action = @game_state.make_fold_action
         begin
            @dealer_communication_service.puts fold_action
         rescue => dealer_communication_error
            throw :game_core_error, dealer_communication_error.message
         end
      end
      
      true
   end
  
   # Sends a raise action to the dealer.
   # @raise (see GameCore#make_bet_action)
   def make_raise_action
      log 'make_raise_action'
      
      if @dealer_communication_service.ready_to_write?
         raise_action = @game_state.make_raise_or_bet_action
         begin
            @dealer_communication_service.puts raise_action
         rescue => dealer_communication_error
            throw :game_core_error, dealer_communication_error.message
         end
      end
      
      true
   end
  
  
   # Game state retrieval methods ----------------------------------------------
  
   # @return [Player] The +Player+ that has the dealer button.
   def player_with_the_dealer_button
      @game_state.player_with_the_dealer_button
   end
 
   # @return [Player] The +Player+ who submitted the big blind.
   def player_who_submitted_big_blind
      @game_state.player_who_submitted_big_blind
   end
   
   # @return [Player] The +Player+ who submitted the small blind.
   def player_who_submitted_small_blind
      @game_state.player_who_submitted_small_blind
   end
 
   # @return [Player] The +Player+ whose turn is next.
   def player_whose_turn_is_next
      @game_state.player_whose_turn_is_next
   end
 
   # (see GameState#player_who_acted_last)
   def player_who_acted_last
      @game_state.player_who_acted_last
   end
 
   # @return [Integer] The current pot size.
   def pot_size
      @game_state.pot_size
   end
 
   # @return [Array] The list of player stacks.
   def list_of_player_stacks
      @game_state.list_of_player_stacks
   end
 
   # (see GameState#users_hole_cards)
   def users_hole_cards
      @game_state.users_hole_cards
   end
  
   # (see GameState#list_of_opponents_hole_cards)
   def list_of_opponents_hole_cards
      @game_state.list_of_opponents_hole_cards
   end
 
   # (see GameState#list_of_betting_actions)
   def list_of_betting_actions
      @game_state.list_of_betting_actions
   end
 
   # (see GameState#list_of_board_cards)
   def list_of_board_cards
      @game_state.list_of_board_cards
   end
 
   # (see GameState#hand_number)
   def hand_number
      @game_state.hand_number
   end
   
   # @return [String] The name of the current match.
   def match_name
      @game_state.match_name
   end
 
   # (see GameState#users_position)
   def users_position
      @game_state.users_position
   end
 
   # (see GameState#last_action)
   def last_action
      @game_state.last_action
   end
 
   # (see GameState#legal_actions)
   def legal_actions
      @game_state.legal_actions
   end

   # (see GameState#round)
   def round
      @game_state.round
   end
   
   # (see GameState#active_players)
   def active_players
      @game_state.active_players
   end
 
   # (see GameState#max_number_of_hands)
   def max_number_of_hands
      @game_state.max_number_of_hands
   end

   # (see GameState#users_turn_to_act?)
   def users_turn_to_act?
      @game_state.users_turn_to_act?
   end
   
   # (see GameState#hand_ended?)
   def hand_ended?
      @game_state.hand_ended?
   end
   
   # (see GameState#match_ended?)
   def match_ended?
      @game_state.match_ended?
   end
   
   # (see GameState#big_blind)   
   def big_blind
      @game_state.big_blind
   end
   
   # (see GameState#small_blind)
   def small_blind
      @game_state.small_blind
   end
   
   # (see GameState#raise_size_in_this_round)
   def raise_size_in_this_round
      @game_state.raise_size_in_this_round
   end
   
   # (see GameState#list_of_player_chip_balances)
   def list_of_player_chip_balances
      @game_state.list_of_player_chip_balances
   end
   
   # The following methods are private ########################################
   private
   
   # @return [String] The next match state string from the dealer.
   def next_match_state
      log "next_match_state"
      
      begin
         raw_match_state = @dealer_communication_service.gets
      rescue => unable_to_get_match_state_string
         throw :incomplete_match_state, unable_to_get_match_state_string.message
      end
      
      log "next_match_state: raw_match_state: #{raw_match_state}"
      
      result = catch(:incomplete_match_state) do MatchstateString.new raw_match_state end
      throw :incomplete_match_state, result unless result.kind_of? MatchstateString
      
      result
   end
   
   def do_or_throw_game_core_error
      begin
         yield
      rescue => error
         throw :game_core_error, error.message
      end
   end
   
   def users_position_relative_to_user
      @game_definition.number_of_players - 1
   end
   
end
