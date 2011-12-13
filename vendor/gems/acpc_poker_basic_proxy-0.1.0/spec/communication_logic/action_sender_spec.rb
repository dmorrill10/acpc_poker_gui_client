
require File.expand_path('../../support/spec_helper', __FILE__)

# Gems
require 'acpc_poker_types'

# Local modules
require File.expand_path('../../support/model_test_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/communication_logic/action_sender', __FILE__)

describe ActionSender do
   include AcpcPokerTypesDefs
   include ModelTestHelper
   
   before(:each) do
      @connection = mock('AcpcDealerCommunicator')
      @mock_action = mock 'PokerAction'
      @matchstate = create_initial_match_state.shift
   end
   
   describe "#send_action" do
      it 'does not send an illegal action and raises an exception' do
         @mock_action.stubs(:to_acpc).twice.returns('illegal action format')
         expect{ActionSender.send_action(@connection, @matchstate, @mock_action)}.to raise_exception(ActionSender::IllegalActionFormat)
      end
      it 'raises an exception if the given match state does not have the proper format' do
         @matchstate.stubs(:to_s).once.returns('illegal match state format')
         expect{ActionSender.send_action(@connection, @matchstate, @mock_action)}.to raise_exception(ActionSender::IllegalMatchStateFormat)
      end
      it 'can send all legal actions through the provided connection without a modifier' do
         PokerAction::LEGAL_ACPC_CHARACTERS.each do |action|
            @mock_action.stubs(:to_acpc).twice.returns(action)
            match_state_string = @matchstate.to_s
            action_that_should_be_sent = match_state_string + ":#{action}"
            @connection.expects(:puts).once.with(action_that_should_be_sent)
            @matchstate.stubs(:to_s).twice.returns(match_state_string)
         
            ActionSender.send_action @connection, @matchstate, @mock_action
         end
      end
      it 'does not send legal unmodifiable actions that have a modifier and raises an exception' do
         (PokerAction::LEGAL_ACPC_CHARACTERS - PokerAction::MODIFIABLE_ACTIONS.values).each do |unmodifiable_action|
            arbitrary_modifier = 9001
            @mock_action.stubs(:to_acpc).twice.returns(unmodifiable_action + arbitrary_modifier.to_s)
            expect{ActionSender.send_action(@connection, @matchstate, @mock_action)}.to raise_exception(ActionSender::IllegalActionFormat)
         end
      end
      it 'can send all legal modifiable actions through the provided connection with a modifier' do
         PokerAction::MODIFIABLE_ACTIONS.values.each do |action|
            arbitrary_modifier = 9001
            action_string = action + arbitrary_modifier.to_s
            @mock_action.stubs(:to_acpc).times(3).returns(action_string)
            match_state_string = @matchstate.to_s
            action_that_should_be_sent = match_state_string + ":#{action_string}"
            @connection.expects(:puts).once.with(action_that_should_be_sent)
            @matchstate.stubs(:to_s).twice.returns(match_state_string)
         
            ActionSender.send_action @connection, @matchstate, @mock_action
         end
      end
   end
end
