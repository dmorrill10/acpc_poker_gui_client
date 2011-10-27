
# Database module
require 'mongoid'

# Rails @todo Remove this dependency
require File.expand_path('../../../config/environment', __FILE__)

# Local classes
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/matchstate_string', __FILE__)
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/player', __FILE__)
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/side_pot', __FILE__)

class Match
   include Mongoid::Document
   
   field :parameters, type: Hash
   field :state, type: MatchstateString
   field :pot, type: SidePot
end
