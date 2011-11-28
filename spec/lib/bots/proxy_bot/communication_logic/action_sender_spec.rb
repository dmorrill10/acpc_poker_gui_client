require 'spec_helper'

# Local modules
require File.expand_path('../../../../../../lib/acpc_poker_types', __FILE__)
require File.expand_path('../../../../../support/model_test_helper', __FILE__)

describe ActionSender do
   include AcpcPokerTypesDefs
   include ModelTestHelper
   
   before(:each) do
      @connection = mock('AcpcDealerCommunicator')
      @matchstate = create_initial_match_state.shift
   end
   
   describe "#send_action" do
      it 'does not send an illegal action and raises an exception' do
         expect{ActionSender.send_action @connection, @matchstate, :illegal_action}.to raise_exception(ActionSender::IllegalAction)
      end
      it 'can send all legal actions through the provided connection without a modifier' do
         action = :raise
         action_that_should_be_sent = @matchstate.to_s + ":#{ACTION_TYPES[action]}"
         
         @connection.expects(:puts).once.with(action_that_should_be_sent)
         
         ActionSender.send_action @connection, @matchstate, action
      end
      it 'can send all legal actions through the provided connection with a modifier' do
         action = :raise
         modifier = 25
         action_that_should_be_sent = @matchstate.to_s + ":#{ACTION_TYPES[action]}#{modifier}"
         
         @connection.expects(:puts).once.with(action_that_should_be_sent)
         
         ActionSender.send_action @connection, @matchstate, action, modifier
      end
   end
end
