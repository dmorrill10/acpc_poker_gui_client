
# Local classes
require File.expand_path('../communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../communication_logic/action_sender', __FILE__)
require File.expand_path('../communication_logic/matchstate_string_receiver', __FILE__)

# A bot that connects to a dealer as a proxy.
class ProxyBot
   
   # @return [MatchstateString] The current match state string.
   attr_reader :match_state_string
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   def initialize(dealer_information)
      dealer_communicator = AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name
   end
   
   # @param [Symbol] action The action to be sent.
   # @param [#to_s] modifier A modifier that should be associated with the
   #  +action+ before it is sent.
   # @raise (see ActionSender#send_action)
   def send_action(action, modifier = nil)
      ActionSender.send_action @dealer_communicator, @match_state_string, action, modifier
   end
   
   # @return [MatchState] 
   def update_match_state!()
      @match_state_string = MatchstateStringReceiver.receive_matchstate_string @dealer_communicator
   end
end
