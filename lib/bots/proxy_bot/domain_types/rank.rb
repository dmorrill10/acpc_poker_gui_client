
# Local modules
require 'application_defs'

# Local mixins
require 'easy_exceptions'

class Rank
   include ApplicationDefs
   
   exceptions :not_a_recognized_rank
   
   # @return [Symbol] This rank's symbol.
   attr_reader :sybmol
   
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
   
   # @return [String] String representation of this rank.
   def to_s
      CARD_RANKS[@symbol]
   end
   
   
   private
   
   # @raise NotARecognizedRank
   def sanity_check_rank(rank)
      raise NotARecognizedRank, rank.to_s unless CARD_RANKS[rank]
   end
end
