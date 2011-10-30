
# Local modules
require 'models_helper'
require 'application_defs'

# Local classes
require 'player'
require 'matchstate_string'
require 'game_definition'

# Class to manage the players in the game.
class MatchState
   include ModelsHelper
   include ApplicationDefs
   include HandEvaluator
   
   # @return [Integer] The position relative to the dealer that is next to act.
   attr_reader :position_relative_to_dealer_next_to_act
   
   # @return [Integer] The position relative to the dealer that acted last.
   attr_reader :position_relative_to_dealer_acted_last
   
   # @return [Integer] The maximum number of hands in the current match.
   attr_reader :max_number_of_hands

   # @param [GameDefinition] game_definition The definition of the game.
   # @param [Array] players An array of players in the game.
   def initialize(game_definition, players, number_of_hands)
      log "initialize"
         
      (@game_definition, @players) = [game_definition, players]
      @max_number_of_hands = number_of_hands.to_i
      @pot_carry_over = 0
   end
   
   
   # Interface to game logic ###################################################
  
   # Player state mutation methods --------------------------------------------
  
   # Updates the state of the players managed by this instance.
   # 
   # @param [MatchstateString] new_match_state
   #     A new match state with which to update the game's state.
   def update_state!(match_state)
      log "update_state!"
      
      @position_relative_to_dealer_acted_last = @position_relative_to_dealer_next_to_act
      
      update! match_state
      
      update_state_of_players!
      
      true
   end   

   # Set internal state player states so that they are ready to start a
   #     new hand.
   #
   # @param [MatchstateString] initial_match_state_for_new_hand
   #     The initial match state for a new hand.
   def start_new_hand!(initial_match_state_for_new_hand)
      log 'start_new_hand!'
      
      reset_players! initial_match_state_for_new_hand
      
      update! initial_match_state_for_new_hand
   end
   
   
   # Player state retrieval methods -------------------------------------------
  
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button
      log 'player_with_the_dealer_button'
      
      @players.each { |player| return player if dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
 
   # (see GameCore#player_who_submitted_big_blind)
   def player_who_submitted_big_blind
      log 'player_who_submitted_big_blind'
      
      @players[player_who_submitted_big_blind_index]
   end
   
   # (see GameCore#player_who_submitted_small_blind)
   def player_who_submitted_small_blind
      log 'player_who_submitted_small_blind'
      
      @players[player_who_submitted_small_blind_index]
   end
   
   # (see GameCore#player_whose_turn_is_next)
   def player_whose_turn_is_next
      log 'player_whose_turn_is_next'
      
      @players[player_whose_turn_is_next_index]
   end
   
   # @return The +Player+ who acted last or nil if none have played yet.
   def player_who_acted_last
      log 'player_who_acted_last'
      
      index = player_who_acted_last_index
      if index then @players[index] else nil end
   end
   
   # (see GameCore#pot_size)
   def pot_size
      log "pot_size: @pot_carry_over: #{@pot_carry_over}"
      
      local_pot_size = @pot_carry_over
      @players.each { |player| local_pot_size += player.number_of_chips_in_the_pot; log "pot_size: local_pot_size: #{local_pot_size}" }
      local_pot_size
   end
 
   # (see GameCore#list_of_player_stacks)
   def list_of_player_stacks
      @players.map { |player| player.stack }
   end
 
   # (see MatchstateString#users_hole_cards)
   def users_hole_cards
      user_player.hole_cards
   end
  
   # (see MatchstateString#list_of_opponents_hole_cards)
   def list_of_opponents_hole_cards
      @match_state.list_of_opponents_hole_cards
   end
 
   # (see MatchstateString#list_of_betting_actions)
   def list_of_betting_actions
      @match_state.list_of_betting_actions
   end
   
   # (see MatchstateString#list_of_board_cards)
   def list_of_board_cards
      @match_state.list_of_board_cards
   end
 
   # (see MatchstateString#hand_number)
   def hand_number
      @match_state.hand_number
   end
   
   # (see MatchstateString#position_relative_to_dealer)
   def users_position
      @match_state.position_relative_to_dealer
   end
 
   # @return [Array] An array of legal actions for the currently acting player.
   def legal_actions
   end
   
   # (see MatchstateString#round)
   def round
      @match_state.round
   end
 
   # @return [Array] The players in the game still currently active.
   def active_players
      @players.select { |player| player.is_active? }
   end

   # (see MatchstateString#last_action)
   def last_action
      @match_state.last_action
   end

   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?
      log "users_turn_to_act?"
      
      users_turn_to_act = @position_relative_to_dealer_next_to_act == users_position
      
      # Check if the match has ended
      users_turn_to_act &= !match_ended?
      
      log "users_turn_to_act?: #{users_turn_to_act}"
      
      users_turn_to_act
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?
      log 'hand_ended?'
      
      less_than_two_active_players? || reached_showdown?
   end
   
   # @return [Boolean] +true+ if the game has ended, +false+ otherwise.
   def match_ended?
      log 'match_ended?'
      
      hand_ended? && last_hand?
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
   
   
   # The following methods are private ########################################
   private
   
   def less_than_two_active_players?
      log "less_than_two_active_players: active_players.length: #{active_players.length}"
      
      boolean = active_players.length < 2
      
      log "less_than_two_active_players: boolean: #{boolean}"
      
      boolean
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   def last_round?
      @game_definition.number_of_rounds - 1 == round 
   end
   
   def opponents_cards_visible?
      log 'opponents_cards_visible?'
      
      are_visible = !((list_of_opponents_hole_cards.reject { |hole_card_set| hole_card_set.empty? }).empty?)
      
      log "opponents_cards_visible?: are_visible: #{are_visible}"
      
      are_visible
   end
      
   def is_reverse_blinds?
      2 == @game_definition.number_of_players
   end
   
   def number_of_active_players
      active_players.length
   end
   
   def update!(match_state)
      log "update!: #{match_state}"
      
      @match_state = match_state
      
      number_of_actions_in_current_round = match_state.number_of_actions_in_current_round
      first_position_in_current_round = @game_definition.first_player_position_in_each_round[round]-1
      
      @position_relative_to_dealer_next_to_act = (first_position_in_current_round + number_of_actions_in_current_round) % number_of_active_players
      
      log "update!: @position_relative_to_dealer_next_to_act: #{@position_relative_to_dealer_next_to_act}, first_position_in_current_round: #{first_position_in_current_round}, number_of_actions_in_current_round: #{number_of_actions_in_current_round}, number_of_active_players: #{number_of_active_players}"
   end
   
   def dealer_position_relative_to_dealer
      @game_definition.number_of_players - 1
   end
   
   def player_with_the_dealer_button_index
      @players.index { |player| dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
 
   def player_who_submitted_big_blind_index
      big_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_big_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_big_blind] end
      index = @players.index do |player|
         log "player_who_submitted_big_blind_index: player.position_relative_to_dealer: #{player.position_relative_to_dealer}"
         player.position_relative_to_dealer == big_blind_position
      end
      
      log "player_who_submitted_big_blind_index: big_blind_position: #{big_blind_position}, index: #{index}"
      
      index
   end
   
   def player_who_submitted_small_blind_index
      small_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_small_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_small_blind] end
      @players.index { |player| player.position_relative_to_dealer == small_blind_position }
   end
   
   def player_whose_turn_is_next_index
      @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_next_to_act }
   end
   
   def player_who_acted_last_index
      @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_acted_last }
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
   
   def user_player
      @players[USERS_INDEX]
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
   
   def update_state_of_players!
      last_player_to_act = @players[player_who_acted_last_index]
      
      log "update_state_of_players!: last_player_to_act.name: #{last_player_to_act.name}"
      
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
      
      log 'update_state_of_players!: exiting cleanly'
   end
   
   def evaluate_end_of_hand!
      local_active_players = active_players
      
      # If there is only one active player, that player has won the pot
      if 1 == local_active_players.length
         local_active_players[0].take_winnings! pot_size
      else
         evaluate_showdown!
      end
   end
   
   def evaluate_showdown!
      assign_hole_cards_to_opponents!
      assign_hand_strength!
      distribute_winnings!
   end
   
   def assign_hand_strength!
      list_of_players_who_have_not_folded.each do |player|
         acpc_cards = player.to_acpc_cards.dup
         
         log "assign_hand_strength!: acpc_cards: #{acpc_cards}, player.hole_cards: #{player.hole_cards}"
            
         list_of_board_cards.each do |board_card|
            acpc_cards << to_acpc_card_from_card_string(board_card)
         end
            
         player.hand_strength = rank_hand(acpc_cards)
         
         log "assign_hand_strength!: acpc_cards: #{acpc_cards}, player.hand_strength: #{player.hand_strength}"
      end
   end
   
   def distribute_winnings!
      distribute_winnings_r! list_of_players_who_have_not_folded, pot_size
   end
   
   def distribute_winnings_r!(list_of_players, amount_to_distribute)
      return if 0 == amount_to_distribute
      
      if 1 == list_of_players.length
         log "distribute_winnings_r!: amount_to_distribute: #{amount_to_distribute}"
         
         list_of_players[0].take_winnings! amount_to_distribute
      else
         distribute_winnings_amongst_multiple_players! list_of_players, amount_to_distribute
      end
   end
   
   # TODO This doesn't work if the player with the strongest hand is in a smaller pot than other players, but this is only an issue in multiplayer. When I do deal with this, I'll have to do a loop until there are no more chips in the pot except the overflow.
   def distribute_winnings_amongst_multiple_players!(list_of_players, amount_to_distribute)
      # Find the stength of the strongest hand
      strength_of_the_strongest_hand = (list_of_players.max { |player1, player2| player1.hand_strength <=> player2.hand_strength}).hand_strength
      
      log "distribute_winnings_amongst_multiple_players: strength_of_the_strongest_hand: #{strength_of_the_strongest_hand}"
         
      # Find all the players that have hands as strong as the strongest hand
      winning_players = list_of_players.select { |player| strength_of_the_strongest_hand == player.hand_strength }
      if 1 == winning_players.length
         # If one player wins outright, set the number of chips that all other players have in the pot to zero
         (list_of_players.reject { |player| player == winning_players[0] }).map { |player| player.number_of_chips_in_the_pot = 0 }
         
         # Recurse
         distribute_winnings_r! winning_players, amount_to_distribute
      else
         # Find the smallest side-pot
         # The smallest side-pot is equal to the smallest amount put in the pot by a winning player multiplied by the number of players that have put as many or more chips in the pot plus all the smaller amounts put in by folded players
         player_who_put_the_least_in_the_pot = list_of_players.min { |player1, player2| player1.number_of_chips_in_the_pot <=> player2.number_of_chips_in_the_pot }
         smallest_amount_from_a_winning_player = player_who_put_the_least_in_the_pot.number_of_chips_in_the_pot
         smaller_amounts_from_folded_players = list_of_players_who_have_folded.inject(0) { |sum, player| sum + player.number_of_chips_in_the_pot }
         
         log "distribute_winnings_amongst_multiple_players: smaller_amounts_from_folded_players: #{smaller_amounts_from_folded_players}"
            
         smallest_side_pot = (smallest_amount_from_a_winning_player * list_of_players.length) + smaller_amounts_from_folded_players
            
         # Split the smallest side-pot among the winners
         amount_each_player_wins = (smallest_side_pot/winning_players.length).floor
         winning_players.each { |player| player.take_winnings! amount_each_player_wins }
            
         # Remove chips from the pot
         list_of_players_who_have_folded.each { |player| player.number_of_chips_in_the_pot = 0 }
         non_winning_players_at_showdown = list_of_players.reject { |player| strength_of_the_strongest_hand == player.hand_strength }
         non_winning_players_at_showdown.each { |player| player.number_of_chips_in_the_pot -= smallest_amount_from_a_winning_player }
         # TODO Is the right behaviour to leave excess chips in the pot when they don't divide easily?
         number_of_chips_taken_out_of_the_pot = amount_each_player_wins * winning_players.length
         @pot_carry_over = smallest_side_pot - number_of_chips_taken_out_of_the_pot
         
         log "distribute_winnings_amongst_multiple_players: number_of_chips_taken_out_of_the_pot: #{number_of_chips_taken_out_of_the_pot}, smallest_side_pot: #{smallest_side_pot}, @pot_carry_over: #{@pot_carry_over}"
         
         new_amount_to_distribute = amount_to_distribute - smallest_side_pot
            
         # Distribute the rest of the pot to the players who won a larger side-pot
         players_who_won_a_larger_side_pot = winning_players.reject { |player| player_who_put_the_least_in_the_pot == player }
         
         log "distribute_winnings_amongst_multiple_players: new_amount_to_distribute: #{new_amount_to_distribute}, amount_each_player_wins: #{amount_each_player_wins}, winning_players.length: #{winning_players.length}"
         
         distribute_winnings_r! players_who_won_a_larger_side_pot, new_amount_to_distribute
      end
   end
   
   def assign_hole_cards_to_opponents!
      local_list_of_hole_cards = @match_state.list_of_hole_card_sets

      list_of_opponent_players.each do |opponent|
         opponent.hole_cards = local_list_of_hole_cards[opponent.position_relative_to_dealer] unless opponent.has_folded
      end
   end
   
   def last_hand?
      # TODO LOOKFIRST move this member variable into PlayerManager
      @max_number_of_hands - 1 == hand_number
   end
end
