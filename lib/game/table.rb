
# Local classes
require File.expand_path('../dealer_information', __FILE__)

# A table participants may join to play poker.
class Table   
   # @return [DealerInformation] The information associated with this table's dealer.
   attr_reader :dealer_information
   
   # @return [Array] The seats of this table.
   attr_reader :seats
   
   # @return [String] The name of this match.
   attr_reader :match_name
   
   # @return [Integer] The random seed of set for this match.
   attr_reader :random_seed
   
   def initialize(dealer_information, match_name, random_seed)
      @dealer_information = dealer_information
      @match_name = match_name
      @random_seed = random_seed
   end
end
