
# Local modules
require File.expand_path('../../../../application_defs', __FILE__)

# Local mixins
require File.expand_path('../../../../mixins/easy_exceptions', __FILE__)

# Sends poker actions according to the ACPC protocol.
class ActionSender
   include ApplicationDefs
   
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
