
# Local modules
require File.expand_path('../../../../../lib/application_defs', __FILE__)

# Local classes
require File.expand_path('../card', __FILE__)
require File.expand_path('../pile_of_cards', __FILE__)

# A hand of cards.
class Hand < PileOfCards
   include ApplicationDefs
   
   # @param [String] hand The string representation of this hand.
   # @param [Array] hand The +Cards+ in this hand.
   def initialize(hand)
      if hand.kind_of? String
         hand_array = []
         for_every_card(hand) do |card|
            hand_array << card
         end
      end
      super hand
   end
   # @see #to_str
   def to_s
      to_str
   end
   # @return [String]
   def to_str
      self.join
   end
   
   private
   
   def for_every_card(string_of_cards)
      all_ranks = CARD_RANKS.values.join
      all_suits = CARD_SUITS.values.join
      
      string_of_cards.scan(/[#{all_ranks}][#{all_suits}]/).each do |string_card|        
         card = Card.new string_card
         yield card
      end
   end
end
