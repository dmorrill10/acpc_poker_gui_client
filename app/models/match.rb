
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
end
