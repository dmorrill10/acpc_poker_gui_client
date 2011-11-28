
# Local classes
require File.expand_path('../communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../communication_logic/acpc_dealer_information', __FILE__)
require File.expand_path('../communication_logic/action_sender', __FILE__)
require File.expand_path('../communication_logic/matchstate_string_receiver', __FILE__)

# A bot that connects to a dealer as a proxy.
class BasicProxy   
   # @param [AcpcDealerInformation] dealer_information Information about the dealer to which this bot should connect.
   def initialize(dealer_information)
      @dealer_communicator = AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name
   end
   
   # @param [Symbol] action The action to be sent.
   # @param [#to_s] modifier A modifier that should be associated with the
   #  +action+ before it is sent.
   # @raise (see ActionSender#send_action)
   def send_action(action, modifier = nil)
      ActionSender.send_action @dealer_communicator, @match_state, action, modifier
   end
   
   # @see MatchstateStringReceiver#receive_match_state_string
   def receive_match_state_string
      @match_state = MatchstateStringReceiver.receive_matchstate_string @dealer_communicator
   end
end
