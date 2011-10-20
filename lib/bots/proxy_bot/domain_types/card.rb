
# Local modules
require 'application_defs'

# Local mixins
require 'easy_exceptions'

class Card
   include ApplicationDefs
   
   exceptions :not_a_recognized_suit, :not_a_recognized_rank
   
   # @return [Rank] This card's rank.
   attr_reader :rank
     
   # @return [Suit] This card's suit.
   attr_reader :suit
   
   # @param [Integer] number_of_chips The number of chips to be made into a stack.
   # @raise (see #sanity_check_suit), (see #sanity_check_rank)
   def initialize(suit, rank)
      sanity_check_suit suit
      sanity_check_rank rank
      
      @suit = suit
      @rank = rank
   end
   
   # @return (see #make_acpc_card)
   def to_acpc
      # TODO move
      #integer_rank = CARD_RANK_NUMBERS[string_rank]
      #integer_suit = CARD_SUIT_NUMBERS[string_suit]
            
      make_acpc_card(@rank.to_i, @suit.to_i)
   end
   
   private
   
   # @raise NotARecognizedSuit
   def sanity_check_suit(suit)
      raise NotARecognizedSuit, suit.to_s unless CARD_SUITS[suit]
   end
   
   # @raise NotARecognizedRank
   def sanity_check_rank(rank)
      raise NotARecognizedRank, rank.to_s unless CARD_RANKS[rank]
   end
   
   # @param [Integer] integer_rank The integer ACPC representation of the card's rank.
   # @param [Integer] integer_suit The integer ACPC representation of the card's suit.
   # @return [Integer] The numeric ACPC representation of the card.
   def make_acpc_card(integer_rank, integer_suit)
      integer_rank * CARD_SUITS.length + integer_suit
   end
end
