
# Local modules
require File.expand_path('../../../../../lib/application_defs', __FILE__)

# Local mixins
require File.expand_path('../../../../../lib/mixins/easy_exceptions', __FILE__)

class Suit
   include ApplicationDefs
   
   exceptions :not_a_recognized_suit
   
   # @return [Symbol] This suit's symbol.
   attr_reader :symbol
   
   # @param [Symbol] suit This suit's symbol.
   # @raise (see #sanity_check_suit)
   def initialize(symbol)
      sanity_check_suit symbol
      
      @symbol = symbol
   end
   
   # @return [Integer] Integer ACPC representation of this rank.
   def to_i
      CARD_SUIT_NUMBERS[to_s]
   end
   
   # @return [String] String representation of this rank.
   def to_s
      CARD_SUITS[@symbol]
   end
   
   private
   
   # @raise NotARecognizedSuit
   def sanity_check_suit(suit)
      raise NotARecognizedSuit, suit.to_s unless CARD_SUITS[suit]
   end
end
