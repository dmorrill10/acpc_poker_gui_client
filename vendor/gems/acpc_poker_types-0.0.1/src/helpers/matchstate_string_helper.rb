# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Assortment of helper methods for the MatchstateString model.
module MatchstateStringHelper
   include AcpcPokerTypesDefs
   
   # Builds a match state string from its given component parts.
   #
   # @param [#to_s] position_relative_to_dealer The position relative to the dealer.
   # @param [#to_s] hand_number The hand number.
   # @param [#to_s] betting_sequence The betting sequence.
   # @param [#to_s] all_hole_cards All the hole cards visible.
   # @param [#to_s, #empty?] board_cards All the community cards on the board.
   # @return [String] The constructed match state string.
   def build_match_state_string(position_relative_to_dealer, hand_number, betting_sequence, all_hole_cards, board_cards)
      string = MATCH_STATE_LABEL + ":#{position_relative_to_dealer}:#{hand_number}:#{betting_sequence}:#{all_hole_cards}"
      string += "#{board_cards}" if board_cards and !board_cards.empty?
      string
   end
end
