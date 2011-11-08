
# Database module
require 'mongoid'

# Local classes
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/matchstate_string', __FILE__)
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/player', __FILE__)
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/side_pot', __FILE__)

class Match
   include Mongoid::Document

   field :port_numbers, type: Array
   field :parameters, type: Hash
   field :state, type: MatchstateString
   field :pot, type: SidePot
   field :players, type: Array
   field :next_match_id, type: String
   
   # Match interface
   field :is_match_ended, type: Boolean
   field :is_users_turn_to_act, type: Boolean
   
   # @todo for testing
   field :player, type: Player
   
   field :states, type: Array
   
   def match_ended?
      is_match_ended
   end
   
   def users_turn_to_act?
      is_users_turn_to_act
   end
   
   def to_s
      "Match state: #{state}"
   end
end
