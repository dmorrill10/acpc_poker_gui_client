
# Database module
require 'mongoid'

# Local class
require 'match_slice'

class Match
   include Mongoid::Document
   embeds_many :slices, class_name: "MatchSlice"

   # Table parameters
   field :port_numbers, type: Array
   #field :parameters, type: Hash
   
   field :match_name
   field :game_definition_file_name
   field :number_of_hands, type: Integer
   field :random_seed, type: Integer
   field :player_names
end
