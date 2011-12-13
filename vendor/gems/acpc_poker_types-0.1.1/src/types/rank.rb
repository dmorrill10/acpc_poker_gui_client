
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

class Rank
   include AcpcPokerTypesDefs
   
   exceptions :not_a_recognized_rank
   
   # @return [Symbol] This rank's symbol.
   attr_reader :symbol
   
   # @param [Symbol] rank This rank's symbol.
   # @raise (see #sanity_check_rank)
   def initialize(symbol)
      sanity_check_rank symbol
      
      @symbol = symbol
   end
   
   # @return [Integer] Integer ACPC representation of this rank.
   def to_i
      CARD_RANK_NUMBERS[to_s]
   end
   
   # @see #to_str
   def to_s
      to_str
   end
   
   # @return [String] String representation of this rank.
   def to_str
      CARD_RANKS[@symbol]
   end
   
   private
   
   # @raise NotARecognizedRank
   def sanity_check_rank(symbol)
      raise NotARecognizedRank, symbol.to_s unless CARD_RANKS[symbol]
   end
end
