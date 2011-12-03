
# Database module
require 'mongoid'

# Local class
require File.expand_path('../match_slice', __FILE__)

class Match
   include Mongoid::Document
   embeds_many :slices, class_name: "MatchSlice"

   # Table parameters
   field :port_numbers, type: Array
   field :player_names
   
   field :match_name
   field :game_definition_key, type: Symbol
   field :game_definition_file_name
   field :number_of_hands, type: Integer
   field :random_seed, type: Integer
   
   # @todo Still need this?
   def parameters
      {'Match name:' => match_name,
         'Game definition file name:' => game_definition_file_name,
         'Number of hands:' => number_of_hands,
         'Random seed:' => random_seed}
   end
end
