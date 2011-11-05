require 'spec_helper'

# Third party
require 'stalker'

# Local classes
require 'match'

describe NewGameController do

   describe "GET 'index'" do
      it "should be successful" do
         get_page_and_check_success 'index'
      end
   end
  
   describe "POST 'two_player_limit'" do
      #it 'should be successful' do
      #   get_page_and_check_success 'two_player_limit'
      #end
      #it 'collects all necessary parameters for starting a match' do
      #   test_collects_all_necessary_parameters generate_match_params
      #end
      #it 'creates a new Match' do
      #   match_params = generate_match_params
      #   
      #   match = mock('Match')
      #   match.stubs(:save).returns(true)
      #   Match.stubs(:new).returns(match)
      #   
      #   test_collects_all_necessary_parameters match_params      
      #end
      it 'handles Match saving errors gracefully' do
         match_params = generate_match_params
         
         match = mock('Match')
         match.stubs(:save).returns(false)
         Match.stubs(:new).returns(match)
         
         post('two_player_limit', random_seed: match_params[:random_seed]).should redirect_to(new_game_path)
         flash[:notice].should_not be_nil
      end
      #it 'starts a dealer instance in the background' do
      #   match_params = generate_match_params
      #   
      #   match = mock('Match')
      #   match.stubs(:save).returns(true)
      #   Match.stubs(:new).returns(match)
      #   id = '10'
      #   match.stubs(:id).returns(id)
      #   
      #   dealer_arguments = [match_params[:match_name],
      #                       match_params[:game_definition_file_name].to_s,
      #                       match_params[:number_of_hands],
      #                       match_params[:random_seed],
      #                       match_params[:player_names].split(/\s*,?\s+/)].flatten
      #   
      #   Stalker.expects(:enqueue).once.with('Start dealer', :dealer_arguments => dealer_arguments, :id => id)
      #   
      #   test_collects_all_necessary_parameters match_params
      #end
      it 'collects all necessary parameters for starting a match, creates a new Match,
      starts a dealer instance in the background, queries the Match for the port numbers' do
         match_params = generate_match_params
         
         match = mock('Match')
         match.stubs(:save).returns(true)
         id = '10'
         match.stubs(:id).returns(id)
         match.stubs(:port_numbers).returns(nil)
         Match.stubs(:new).returns(match)
         
         updated_match = mock('Match')
         updated_match.stubs(:port_numbers).returns([9001, 9002])
         Match.stubs(:find).with(id).returns(updated_match)
         
         dealer_arguments = [match_params[:match_name],
                             match_params[:game_definition_file_name].to_s,
                             match_params[:number_of_hands],
                             match_params[:random_seed],
                             match_params[:player_names].split(/\s*,?\s+/)].flatten
         
         Stalker.expects(:enqueue).once.with('Dealer.start', :match_id => id, :dealer_arguments => dealer_arguments)
         
         test_collects_all_necessary_parameters match_params
         flash[:notice].should == ('Port numbers: ' + updated_match.port_numbers.to_s)
      end
      it 'starts a player proxy in the background' do
         pending
      end
      it 'starts the other players in the match' do
         pending
      end
   end

   def get_page_and_check_success(page_name)
      get page_name
      response.should be_success
   end
   
   def test_collects_all_necessary_parameters(match_params)
      post('two_player_limit', random_seed: match_params[:random_seed]).should be_success
      
      match_params_string_keys = {}
      match_params.each { |key, value| match_params_string_keys[key.to_s] = value }
      assigns[:match_params].should be == match_params_string_keys
   end
   
   def generate_match_params
      {port_number: '18791', match_name: 'default',
         game_definition_file_name: GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker],
         number_of_hands: '1', random_seed: '1', player_names: 'user, p2'}
   end
end
