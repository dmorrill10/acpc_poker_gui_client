
require File.expand_path('../support/spec_helper', __FILE__)

# Gems
require 'acpc_poker_types'

# Local classes
require File.expand_path('../../src/basic_proxy', __FILE__)

describe BasicProxy do
   before(:each) do
      @mock_match_state = mock 'MatchstateString'
      
      port_number = 9001
      host_name = 'localhost'
      delaer_info = mock 'AcpcDealerInformation'
      delaer_info.stubs(:host_name).once.returns(host_name)
      delaer_info.stubs(:port_number).once.returns(port_number)
      @dealer_communicator = mock 'AcpcDealerCommunicator'
      AcpcDealerCommunicator.stubs(:new).once.with(port_number, host_name).returns(@dealer_communicator)
      
      @patient = BasicProxy.new delaer_info
   end
   
   it "receives match state strings properly" do
      receive_a_match_state
   end
   
   describe '#send_action' do
      it 'raises an exception if a match state was not received before an action was sent' do
         expect{@patient.send_action(mock('PokerAction'))}.to raise_exception(BasicProxy::InitialMatchStateNotYetReceived)
      end
      it 'sends actions propertly' do
         receive_a_match_state
         mock_action = mock 'PokerAction'
         
         ActionSender.expects(:send_action).once.with(@dealer_communicator, @mock_match_state, mock_action)
         
         @patient.send_action mock_action
      end
   end
   
   def receive_a_match_state
      MatchstateStringReceiver.stubs(:receive_matchstate_string).returns(@mock_match_state)
         
      @patient.receive_match_state_string.should be @mock_match_state
      @patient.instance_eval{ @match_state }.should be @mock_match_state
   end
end