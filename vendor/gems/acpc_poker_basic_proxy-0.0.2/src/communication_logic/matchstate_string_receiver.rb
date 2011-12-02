
# @todo Only want MatchstateString here, is there a way to select this?
require 'acpc_poker_types'

# Receives and parses matchstate strings.
class MatchstateStringReceiver
   
   # Receives a match state string from the given +connection+.
   # @param [#gets] connection The connection from which a matchstate string should be received.
   # @return [MatchstateString] The matchstate string that was received from the +connection+.
   def self.receive_matchstate_string(connection)
      raw_match_state_string = connection.gets
      MatchstateString.new(raw_match_state_string)
   end
end
