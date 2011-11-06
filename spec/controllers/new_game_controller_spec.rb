require 'spec_helper'

# Third party
require 'stalker'

# Local modules
require File.expand_path('../../../lib/application_defs', __FILE__)
require File.expand_path('../../support/controller_test_helper', __FILE__)

# Local classes
require 'match'

describe NewGameController do
   include ApplicationDefs
   include ControllerTestHelper

   describe "GET 'index'" do
      it "should be successful" do
         get_page_and_check_success 'index'
      end
   end
  
   describe "POST 'two_player_limit'" do
      it 'handles Match saving errors gracefully' do
         match_params = generate_match_params
         
         match = mock('Match')
         match.stubs(:save).returns(false)
         Match.stubs(:new).returns(match)
         
         post('two_player_limit', random_seed: match_params[:random_seed]).should redirect_to(new_game_path)
         flash[:notice].should_not be_nil
      end
      it 'collects all necessary parameters for starting a match, creates a new Match, starts a dealer instance in the background, queries the Match for the port numbers, and sends the appropriate parameters to PlayerActionsController' do
         match_params = generate_match_params
         
         # Mock and stub out the Match class and its instances
         match = mock('Match')
         match.stubs(:save).returns(true)
         id = '10'
         match.stubs(:id).returns(id)
         match.stubs(:port_numbers).returns(nil)
         Match.stubs(:new).returns(match)
         updated_match = mock('Match')
         updated_match.stubs(:port_numbers).returns([9001, 9002])
         Match.stubs(:find).with(id).returns(updated_match)
         
         # Make sure the dealer is started with the correct parameters
         dealer_arguments = [match_params[:match_name],
                             match_params[:game_definition_file_name].to_s,
                             match_params[:number_of_hands],
                             match_params[:random_seed],
                             match_params[:player_names].split(/\s*,?\s+/)].flatten
         Stalker.expects(:enqueue).once.with('Dealer.start', :match_id => id, :dealer_arguments => dealer_arguments)
         
         # Send a request to the controller and check that everything is working properly
         test_collects_all_necessary_parameters match_params
         flash[:notice].should == ('Port numbers: ' + updated_match.port_numbers.to_s)
      end
      it 'starts the other players in the match' do
         pending
      end
   end
   
   def test_collects_all_necessary_parameters(match_params)
      post('two_player_limit', random_seed: match_params[:random_seed]).should render_template('shared_javascripts/send_parameters_to_connect_to_dealer.js')
      
      match_params_string_keys = {}
      match_params.each { |key, value| match_params_string_keys[key.to_s] = value }
      assigns[:match_params].should be == match_params_string_keys
   end
end



