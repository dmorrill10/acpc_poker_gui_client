
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
   
   # @return [String] The path to this card's image.
   attr_reader :image_path
   
   IMAGE_DIRECTORY_BASE = 'SVG_and_EPS_Vector_Playing_Cards_Version_1.3/SVG_Vector_Playing_Cards_Version_1.3/'
      
   def initialize(card_string_or_rank=nil, suit=nil)
      # This is a facedown card if no arguments were given
      if card_string_or_rank.nil?
         # @todo Move this out to the defs file maybe.
         @image_path = "#{IMAGE_DIRECTORY_BASE}/Backs_and_pips_1.3_(No_Crop_Marks)/Red_Back.svg"
      elsif suit
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
      
      @image_path = image_path_for_card rank, suit
   end
   
   def image_path_for_card(rank, suit)
      # @todo Move this out to the defs file maybe.
      rank_conversion = {two: '2', three: '3', four: '4', five: '5',
         six: '6', seven: '7', eight: '8', nine: '9', ten: '10',
         jack: 'J', queen: 'Q', king: 'K', ace: 'A'}
      suit_conversion_for_file = {clubs: 'C', diamonds: 'D', hearts: 'H', spades: 'S'}
      suit_conversion_for_directory = {clubs: 'Clubs', diamonds: 'Diamonds',
         hearts: 'Hearts', spades: 'Spades'}
      
      rank_for_image_file_path = rank_conversion[rank]
      suit_for_image_file_path = suit_conversion_for_file[suit]
      suit_for_image_directory_path = suit_conversion_for_directory[suit]
      
      "#{IMAGE_DIRECTORY_BASE}/52-Individual-Color-Vector-Playing_Cards-1.3_(SVG-Format_No_Crop_Marks)/#{suit_for_image_directory_path}/#{rank_for_image_file_path}#{suit_for_image_file_path}.svg"
   end
end
