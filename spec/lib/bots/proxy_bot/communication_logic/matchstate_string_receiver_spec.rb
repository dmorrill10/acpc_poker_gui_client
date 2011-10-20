require 'spec_helper'

# Local classes
require 'matchstate_string'

describe MatchstateStringReceiver do
   before(:each) do
      @connection = mock('AcpcDealerCommunicator')
      (@matchstate, user_position) = create_initial_match_state
   end
   
   describe "#receive_matchstate_string" do
      it 'receives matchstate strings properly' do
         raw_matchstate_string = @matchstate.to_s
         @connection.stubs(:gets).returns(raw_matchstate_string)
         real_matchstate_string = MatchstateString.new raw_matchstate_string
         
         MatchstateStringReceiver.receive_matchstate_string(@connection).should eq(real_matchstate_string)
      end
   end
end
