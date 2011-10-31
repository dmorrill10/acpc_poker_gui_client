
# Local modules
require File.expand_path('../../../../../lib/application_defs', __FILE__)

# Local classes
require File.expand_path('../../domain_types/matchstate_string', __FILE__)

# Receives and parses matchstate strings.
class MatchstateStringReceiver
   include ApplicationDefs
   
   # Receives a matchstate string from the given +connection+.
   # @param [#gets] connection The connection from which a matchstate string should be received.
   # @return [MatchstateString] The matchstate string that was received from the +connection+.
   def self.receive_matchstate_string(connection)         
      MatchstateString.new(connection.gets)
   end
end
