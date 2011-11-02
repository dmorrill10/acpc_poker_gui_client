require 'spec_helper'

# Local classes
require File.expand_path('../../../../../lib/bots/proxy_bot/communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../../../../../lib/bots/proxy_bot/communication_logic/action_sender', __FILE__)
require File.expand_path('../../../../../lib/bots/proxy_bot/domain_types/card', __FILE__)
require File.expand_path('../../../../../lib/bots/proxy_bot/communication_logic/matchstate_string_receiver', __FILE__)
require File.expand_path('../../../../../lib/game/dealer_information', __FILE__)

describe ProxyBot do
   before(:each) do
      @match_state = mock('MatchstateString')
      
      port_number = 9001
      host_name = 'localhost'
      delaer_info = DealerInformation.new host_name, port_number
      AcpcDealerCommunicator.expects(:new).once.with(port_number, host_name)
      
      @patient = ProxyBot.new delaer_info
   end
   
   describe '#receive_match_state_string' do
      it "updates its match state properly" do
         MatchstateStringReceiver.stubs(:receive_matchstate_string).returns(@match_state)
         
         @patient.receive_match_state_string.should be @match_state
      end
   end
end