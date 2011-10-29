
# System classes
require 'set'

# A hand of cards.
class Hand
   
   # @return [Set] The set of cards in this hand.
   attr_reader :cards

   def initialize(set_of_cards)
      @cards = set_of_cards.to_set
   end
end
