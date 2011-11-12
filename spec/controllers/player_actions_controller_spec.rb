require 'spec_helper'

# Local modules
require File.expand_path('../../support/controller_test_helper', __FILE__)

describe PlayerActionsController do
   include ControllerTestHelper
   
   describe "POST 'index'" do
      it 'collects all necessary parameters for starting a player proxy, starts a player proxy in the background' do
         match_params = generate_match_params
         
         # Mock and stub out the Match class and its instances
         match = mock('Match')
         match_params[:match_id] = '10'
         id = match_params[:match_id]
         match.stubs(:id).returns(id)
         match.stubs(:state).returns(nil)
         Match.stubs(:new).returns(match)
         updated_match = mock('Match')
         updated_match.stubs(:state).returns('match_state')
         Match.stubs(:find).with(id).returns(updated_match)
         
         # Make sure a player proxy is started with the correct parameters
         player_proxy_arguments = {match_id: match_params[:match_id], host_name: 'localhost', port_number: match_params[:port_number], game_definition_file_name: match_params[:game_definition_file_name], number_of_hands: match_params[:number_of_hands]}
         Stalker.expects(:enqueue).once.with('PlayerProxy.start', player_proxy_arguments)
         
         test_collects_all_necessary_parameters match_params
      end
   end
   
   def test_collects_all_necessary_parameters(match_params)
      post('index', match_params).should render_template('shared_javascripts/replace_contents.js')
      
      assigns[:replacement_partial].should be == 'player_actions/index'
      
      match_params_string_keys = {}
      match_params.each { |key, value| match_params_string_keys[key.to_s] = value }
      assigns[:match_params].should be == match_params_string_keys
   end
end
