
# Local classes
require File.expand_path('../pile_of_cards', __FILE__)

# A hand of cards.
class Hand < PileOfCards
   # @see #to_str
   def to_s
      to_str
   end
   # @return [String]
   def to_str
      self.join
   end
end
