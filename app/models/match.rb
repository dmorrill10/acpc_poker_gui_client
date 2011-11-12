
# Database module
require 'mongoid'

# Local class
require 'match_slice'

class Match
   include Mongoid::Document
   embeds_many :slices, class_name: "MatchSlice"

   # Table parameters
   field :port_numbers, type: Array
   field :parameters, type: Hash
end
