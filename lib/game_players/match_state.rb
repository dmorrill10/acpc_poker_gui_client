require 'models_helper'
require 'match_state_helper'

# Model to parse and manage information from a given match state string.
class MatchState
   include ModelsHelper
   include MatchStateHelper
   
   # @return [Integer] The position relative to the dealer of the player that
   #     received the match state string, indexed from 0, modulo the
   #     number of players.
   # @example The player immediately to the left of the dealer has
   #     +position_relative_to_dealer+ == 0
   # @example The dealer has
   #     +position_relative_to_dealer+ == <number of players> - 1
   attr_reader :position_relative_to_dealer
   
   # @return [Integer] The hand number.
   attr_reader :hand_number
   
   # @return [String] The sequence of betting actions.
   attr_reader :betting_sequence
   
   # @return [String] All visible hole cards.
   attr_reader :all_hole_cards
   
   # @return [String] All visible community cards on the board.
   attr_reader :board_cards
   
   
   # @param [String] raw_match_state A raw match state string to be parsed.
   # @raise [:incomplete_match_state] +raw_match_state+ is an incomplete match state.
   def initialize(raw_match_state)
      throw :incomplete_match_state, raw_match_state if line_is_comment_or_empty? raw_match_state
   
      all_actions = ACTION_TYPES.values.join ''
      all_ranks = CARD_RANKS.values.join ''
      all_suits = CARD_SUITS.values.join ''
      all_card_tokens = all_ranks + all_suits
   
      if raw_match_state.match(
              /#{MATCH_STATE_LABEL}:(\d+):(\d+):([\d#{all_actions}\/]*):([|#{all_card_tokens}]+)\/*([\/#{all_card_tokens}]*)/
              )
         @position_relative_to_dealer = $1.to_i
         @hand_number = $2.to_i
         @betting_sequence = $3
         @all_hole_cards = $4
         @board_cards = $5
      end
      
      log "initialize: @position_relative_to_dealer: #{@position_relative_to_dealer},     
      @hand_number: #{@hand_number},
      @betting_sequence: #{@betting_sequence},
      @all_hole_cards: #{@all_hole_cards},
      @board_cards: #{@board_cards}"
   
      throw :incomplete_match_state, raw_match_state if incomplete_match_state?      
   end

   # @return [String] The match state in text form.
   def to_s
      build_match_state_string @position_relative_to_dealer, @hand_number,
         @betting_sequence, @all_hole_cards, @board_cards
   end
   
   # @return [String] The last action taken.
   def last_action
      list_of_betting_actions[-1]
   end

   # @return [Array] The list of betting actions.
   def list_of_betting_actions
      list_of_actions @betting_sequence
   end

   # @return [String] The user's hole cards.
   # @example An ace of diamonds and a 4 of clubs is represented as
   #     'Ad4c'
   def users_hole_cards
      local_list_of_hole_card_sets = list_of_hole_card_sets
      
      log "users_hole_cards: local_list_of_hole_card_sets: #{local_list_of_hole_card_sets}, @position_relative_to_dealer: #{@position_relative_to_dealer}"
      
      local_list_of_hole_card_sets[@position_relative_to_dealer]
   end
   
   # @return [Array] The list of opponent hole cards that are visible.
   # @example If there are two opponents, one with AhKs and the other with QdJc, then
   #     list_of_opponents_hole_cards == ['AhKs', 'QdJc']
   def list_of_opponents_hole_cards
      local_list_of_hole_card_sets = list_of_hole_card_sets
      local_list_of_hole_card_sets.delete_at @position_relative_to_dealer
      
      log "list_of_opponents_hole_cards: list_of_hole_card_sets: #{list_of_hole_card_sets}, @position_relative_to_dealer: #{@position_relative_to_dealer}, local_list_of_hole_card_sets: #{local_list_of_hole_card_sets}"
      
      local_list_of_hole_card_sets
   end

   # @return [Array] The list of community cards on the board.
   # @example In Texas hold'em, if the board shows AhKsQd/Jc/Td, then
   #     list_of_board_cards == [Ah, Ks, Qd, Jc, Td]
   def list_of_board_cards
      @board_cards.split(/\//)
   end
   
   # @return [Integer] The zero indexed current round number.
   def round
      log "round: @betting_sequence: #{@betting_sequence}"
      
      @betting_sequence.scan(/\//).length
   end
   
   # @return [Integer] The number of actions in the current round.
   def number_of_actions_in_current_round
      log "number_of_actions_in_current_round: @betting_sequence: #{@betting_sequence}"
      
      betting_sequence_in_each_round = if (split_result = @betting_sequence.split(/\//)).empty?
         then [@betting_sequence,] else split_result end
      
      log "number_of_actions_in_current_round: betting_sequence_in_each_round: #{betting_sequence_in_each_round}"
      
      if @betting_sequence.match(/\/$/)
         number_of_actions = 0
      else
         number_of_actions = list_of_actions(betting_sequence_in_each_round[round]).length
      end
      
      log "number_of_actions_in_current_round: number_of_actions #{number_of_actions}"
      
      number_of_actions
   end
   
   # @return [Array] The list of visible hole card sets for each player.
   def list_of_hole_card_sets
      @all_hole_cards.split(/\|/)
   end
   
   
   # All following methods are private ########################################
   private
   
   def list_of_actions(betting_sequence)
      all_actions = ACTION_TYPES.values.join ''
      betting_sequence.scan(/[#{all_actions}]\d*/)
   end
   
   def incomplete_match_state?
      !(@position_relative_to_dealer and @hand_number and @all_hole_cards)
   end

end
