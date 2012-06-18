
# Database module
require 'mongoid'
Mongoid.logger = nil

# Local class
require File.expand_path('../match_slice', __FILE__)

class Match
   include Mongoid::Document
   include Mongoid::Timestamps::Updated
   
   def self.include_match_name
      field :match_name
      validates_presence_of :match_name
      validates_uniqueness_of :match_name
   end
   
   def self.include_game_definition
      field :game_definition_key, type: Symbol
      validates_presence_of :game_definition_key
      field :game_definition_file_name
   end
   
   def self.include_number_of_hands
      field :number_of_hands, type: Integer
      validates_presence_of :number_of_hands
      validates_numericality_of :number_of_hands, greater_than: 0, only_integer: true
   end
   
   def self.include_random_seed
      field :random_seed, type: Integer
   end
   
   def self.include_opponent_agent
      field :bot, type: String
      validates_presence_of :bot
   end
   
   embeds_many :slices, class_name: "MatchSlice"

   # Table parameters
   field :port_numbers, type: Array
   field :player_names
   field :millisecond_response_timeout, type: Integer
   field :seat, type: Integer
   
   include_match_name
   include_game_definition   
   include_number_of_hands
   include_random_seed
   include_opponent_agent
   
   # Game definition information
   field :betting_type, type: String
   field :number_of_hole_cards, type: Integer
   
   def self.delete_matches_older_than(lifespan)
      where(:updated_at.lt => (Time.new - lifespan)).delete_all
   end
   
   def parameters
      {'Match name:' => match_name,
         'Game definition file name:' => game_definition_file_name,
         'Number of hands:' => number_of_hands,
         'Random seed:' => random_seed}
   end
end
