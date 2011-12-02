
# Assortment of constant definitions and methods for generating default values.
module AcpcPokerMatchStateDefs

   # @return [Integer] The user's index in the array of Player.
   USERS_INDEX = 0;
   
   # @return [Hash] Reversed blind positions relative to the dealer (used in a heads up (2 player) game).
   BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS = {:submits_big_blind => 0, :submits_small_blind => 1}
   
   # @return [Hash] Normal blind positions relative to the dealer.
   BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS = {:submits_big_blind => 1, :submits_small_blind => 0}
end
