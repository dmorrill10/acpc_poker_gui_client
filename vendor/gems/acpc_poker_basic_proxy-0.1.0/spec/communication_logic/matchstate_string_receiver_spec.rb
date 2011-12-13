
require File.expand_path('../../support/spec_helper', __FILE__)

# Gems
require 'acpc_poker_types'

# Local modules
require File.expand_path('../../support/model_test_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/communication_logic/matchstate_string_receiver', __FILE__)

describe MatchstateStringReceiver do
   include ModelTestHelper
   
   before(:each) do
      @connection = mock('AcpcDealerCommunicator')
      @matchstate = create_initial_match_state.shift
   end
   
   describe "#receive_matchstate_string" do
      it 'receives matchstate strings properly' do
         raw_matchstate_string = @matchstate.to_s
         @connection.expects(:gets).once.returns(raw_matchstate_string)
         MatchstateString.stubs(:new).returns(@matchstate)
         
         MatchstateStringReceiver.receive_matchstate_string(@connection).should be @matchstate
      end
   end
end
