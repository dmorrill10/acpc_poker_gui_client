
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Local classes
require File.expand_path('../card', __FILE__)
require File.expand_path('../pile_of_cards', __FILE__)

# A hand of cards.
class Hand < PileOfCards
   include AcpcPokerTypesDefs
      
   # @param [String] hand_in_alternate_form An alternate representation of this hand.
   def self.draw_cards(hand_in_alternate_form)
      unless hand_in_alternate_form.kind_of?(Array)
         hand_array = []
         for_every_card(hand_in_alternate_form) do |card|
            hand_array << card
         end
         hand_in_alternate_form = hand_array
      end
      Hand.new hand_in_alternate_form
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
   
   def self.for_every_card(string_of_cards)
      all_ranks = CARD_RANKS.values.join
      all_suits = CARD_SUITS.values.join
      
      string_of_cards.scan(/[#{all_ranks}][#{all_suits}]/).each do |string_card|        
         card = Card.new string_card
         yield card
      end
   end
end
