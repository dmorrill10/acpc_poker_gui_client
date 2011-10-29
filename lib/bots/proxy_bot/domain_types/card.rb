
# Local modules
require File.expand_path('../../../../../lib/application_defs', __FILE__)

# Local mixins
require File.expand_path('../../../../../lib/mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)

class Card
   include ApplicationDefs
   
   # @return [Rank] This card's rank.
   attr_reader :rank
     
   # @return [Suit] This card's suit.
   attr_reader :suit
   
   # @param [Rank] rank This card's rank.
   # @param [Suit] suit This card's suit.
   # @raise (see Rank#initialize)
   # @raise (see Suit#initialize)
   def initialize(rank, suit)
      @rank = Rank.new rank
      @suit = Suit.new suit
   end
   
   # @return (see #make_acpc_card)
   def to_i
      make_acpc_card(@rank.to_i, @suit.to_i)
   end
   
   # @return [String] This card's string representation.
   def to_s
      @rank.to_s + @suit.to_s
   end
   
   private
   
   # @param [Integer] integer_rank The integer ACPC representation of the card's rank.
   # @param [Integer] integer_suit The integer ACPC representation of the card's suit.
   # @return [Integer] The numeric ACPC representation of the card.
   def make_acpc_card(integer_rank, integer_suit)
      integer_rank * CARD_SUITS.length + integer_suit
   end
end
