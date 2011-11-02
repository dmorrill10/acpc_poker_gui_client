
# Local classes
require File.expand_path('../card', __FILE__)
require File.expand_path('../pile_of_cards', __FILE__)

# A hand of cards.
class Hand < PileOfCards
   # @param [String] hand The string representation of this hand.
   # @param [Array] hand The +Cards+ in this hand.
   def initialize(hand)
      if string_hand.kind_of? String
         # @todo fix
         for_every_card(string_hand) do |card|
            hand << card
         end
         string_hand
      else
         super hand
      end
   end
   # @see #to_str
   def to_s
      to_str
   end
   # @return [String]
   def to_str
      self.join
   end
end
