
# @todo Only want AcpcPokerTypesDefs and easy_exceptions here, is there a way to select this?
require 'acpc_poker_types'

# Sends poker actions according to the ACPC protocol.
class ActionSender
   include AcpcPokerTypesDefs
   
   exceptions :illegal_action
   
   # Sends the given +action+ to through the given +connection+ in the ACPC
   # format.
   # @param [#puts] connection The connection through which the +action+
   #  should be sent.
   # @param [MatchstateString] match_state The current match state.
   # @param [Symbol] action The action to be sent through the +connection+.
   # @param [#to_s] modifier A modifier that should be associated with the
   #  +action+ before it is sent.
   # @raise IllegalAction
   def self.send_action(connection, match_state, action, modifier = nil)
      raise IllegalAction unless ACTION_TYPES[action]
         
      full_action = match_state.to_s + ":#{ACTION_TYPES[action]}"      
      full_action += modifier.to_s if modifier
      
      connection.puts full_action
   end
end
