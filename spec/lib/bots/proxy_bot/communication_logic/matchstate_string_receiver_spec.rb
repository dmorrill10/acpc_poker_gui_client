require 'spec_helper'

# Local modules
require File.expand_path('../../../../../support/model_test_helper', __FILE__)

# Local classes
require File.expand_path('../../../../../../lib/bots/proxy_bot/domain_types/matchstate_string', __FILE__)

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
