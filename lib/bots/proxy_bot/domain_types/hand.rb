
# Database module
require 'mongoid'

# Local modules
require File.expand_path('../../../../../lib/application_defs', __FILE__)

# Local classes
require File.expand_path('../card', __FILE__)
require File.expand_path('../pile_of_cards', __FILE__)

# A hand of cards.
class Hand < PileOfCards
   include ApplicationDefs
   include Mongoid::Fields::Serializable
   
   # @param [String] hand The string representation of this hand.
   def self.draw_cards(hand)
      if hand.kind_of? String
         hand_array = []
         for_every_card(hand) do |card|
            hand_array << card
         end
         hand = hand_array
      end
      Hand.new hand
   end
   
   # @todo Mongoid method
   def deserialize(string_hand)
      Hand.draw_cards string_hand
   end

   # @todo Mongoid method
   def serialize(hand)
      hand.to_str
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
