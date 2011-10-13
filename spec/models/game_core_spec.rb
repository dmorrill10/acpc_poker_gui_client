require 'spec_helper'
#require 'application_defs'

describe GameCore do

   #include ApplicationDefs
   
   #before(:each) do
   #   @dealer_communication = mock('DealerCommunication')
   #   @raw_match_state =  MATCH_STATE_LABEL + ":1:1::" + arbitrary_hole_card_hand
   #   @dealer_communication.stubs(:get_match_state_string_from_dealer).returns(@raw_match_state)
   #end
   
   #it "parses all available game definitions properly" do
   #   GAME_DEFINITION_FILE_NAMES.values.each do |game_definition_file_name|
   #      patient = catch(:game_error) do
   #         GameDefinition.new game_definition_file_name, @dealer_communication
   #      end
   #      describe "Parse the valid game definition file, \"#{game_definition_file_name}\"" do
   #         it "does not throw an error when #{game_definition_file_name} is parsed" do
   #            patient.should be_a_kind_of GameDefinition
   #         end
   #         it "parses #{game_definition_file_name} properly" do
   #            matched = parsed_game_definitions_match_original_definitions?(patient, game_definition_file_name)
   #            matched.should == true
   #         end
   #      end
   #   end
   #end
   #it "submits actions correctly" do
   #   for_each_game_definition_file do |patient|
   #      ACTION_TYPES.values.each do |action|
   #         expected_string = @raw_match_state + ':' + action + TERMINATION_STRING
   #         @dealer_communication.stubs(:puts).once.with(expected_string)
   #         patient.submit_action action
   #      end
   #   end
   #end
   #it "records the last opponent action correctly" do
   #   first_part_of_match_state = MATCH_STATE_LABEL + ":0:0:"
   #   second_part_of_match_state = ":" + arbitrary_hole_card_hand
   #   initial_match_state = first_part_of_match_state + second_part_of_match_state
   #   @dealer_communication.stubs(:get_match_state_string_from_dealer).returns(initial_match_state)
   #   for_each_game_definition_file do |patient|
   #      ACTION_TYPES.values.each do |action|
   #         opponent_match_state = first_part_of_match_state + action + second_part_of_match_state
   #         @dealer_communication.stubs(:get_match_state_string_from_dealer).returns(opponent_match_state)
   #         patient.update_match_state
   #         patient.last_opponent_action.should be == action
   #      end
   #      # Check a no limit action as well
   #      no_limit_action = ACTION_TYPES[:raise] + "123"
   #      opponent_match_state = first_part_of_match_state + no_limit_action + second_part_of_match_state
   #      @dealer_communication.stubs(:get_match_state_string_from_dealer).returns(opponent_match_state)
   #      patient.update_match_state
   #      patient.last_opponent_action.should be == no_limit_action
   #   end      
   #end
   #
   #it "records the last user action correctly" do
   #   first_part_of_match_state = MATCH_STATE_LABEL + ":0:0:"
   #   second_part_of_match_state = ":" + arbitrary_hole_card_hand + "|"
   #   initial_match_state = first_part_of_match_state + second_part_of_match_state
   #   @dealer_communication.stubs(:get_match_state_string_from_dealer).returns(initial_match_state)
   #   GAME_DEFINITION_FILE_NAMES.values.each do |game_definition_file_name|
   #      patient = catch(:game_error) do
   #         Game.new game_definition_file_name, @dealer_communication
   #      end
   #      patient.should be_a_kind_of Game
   #      ACTION_TYPES.values.each do |action|
   #         user_match_state = first_part_of_match_state + second_part_of_match_state + ":#{action}#{TERMINATION_STRING}"
   #         @dealer_communication.expects(:puts).with(user_match_state)
   #         patient.submit_action action
   #         patient.last_user_action.should be == action
   #      end
   #      # Check a no limit action as well
   #      no_limit_action = ACTION_TYPES[:raise] + "123"
   #      user_match_state = first_part_of_match_state + second_part_of_match_state + ":#{no_limit_action}#{TERMINATION_STRING}"
   #      @dealer_communication.expects(:puts).with(user_match_state)
   #      patient.submit_action no_limit_action
   #      patient.last_user_action.should be == no_limit_action
   #   end
   #end
   #
   #it "properly adjusts the current wager based on player actions" do
   #   pending "TODO"
   #end

end
