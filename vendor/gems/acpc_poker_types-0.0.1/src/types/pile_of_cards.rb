
# Local modules
require File.expand_path('../../ext/hand_evaluator', __FILE__)


# A set of cards.
class PileOfCards < Array
   
   # @return [Integer] The strength of the strongest poker hand that can be made from this pile of cards.
   def to_poker_hand_strength
      HandEvaluator.rank_hand map { |card| card.to_i }
   end
end
