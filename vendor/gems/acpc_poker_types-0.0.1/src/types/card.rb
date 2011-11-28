
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)

class Card
   include AcpcPokerTypesDefs
   
   exceptions :unable_to_parse_string_of_cards
   
   # @return [Rank] This card's rank.
   attr_reader :rank
     
   # @return [Suit] This card's suit.
   attr_reader :suit
      
   def initialize(card_string_or_rank, suit=nil)
      if suit
         create_with_rank_and_suit card_string_or_rank, suit
      else
         all_ranks = CARD_RANKS.values.join
         all_suits = CARD_SUITS.values.join
      
         if card_string_or_rank.match(/([#{all_ranks}])([#{all_suits}])/)
            string_rank = $1
            string_suit = $2
            symbol_rank = CARD_RANKS.key(string_rank)
            symbol_suit = CARD_SUITS.key(string_suit)
         
            create_with_rank_and_suit symbol_rank, symbol_suit
         else
            raise UnableToParseStringOfCards, card_string_or_rank
         end
      end
   end
   
   # @return (see #make_acpc_card)
   def to_i
      make_acpc_card(@rank.to_i, @suit.to_i)
   end
   
   # @return [String] This card's string representation.
   def to_s
      to_str
   end
   
   # @return [String] This card's string representation.
   def to_str
      @rank.to_s + @suit.to_s
   end
   
   private
   
   # @param [Integer] integer_rank The integer ACPC representation of the card's rank.
   # @param [Integer] integer_suit The integer ACPC representation of the card's suit.
   # @return [Integer] The numeric ACPC representation of the card.
   def make_acpc_card(integer_rank, integer_suit)
      integer_rank * CARD_SUITS.length + integer_suit
   end
   
   # @param [Symbol] rank This card's rank.
   # @param [Symbol] suit This card's suit.
   # @raise (see Rank#initialize)
   # @raise (see Suit#initialize)
   def create_with_rank_and_suit(rank, suit)
      @rank = Rank.new rank
      @suit = Suit.new suit
   end
end
