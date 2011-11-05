require 'spec_helper'

describe NewGameController do

   describe "GET 'index'" do
      it "should be successful" do
         get_page_and_check_success 'index'
      end
   end
  
   describe "GET 'two_player_limit'" do
      it 'should be successful' do
         get_page_and_check_success 'two_player_limit'
      end
      it 'collects arguments from the view' do
         pending 'set variables as if they would from the view and check @match_params'
         
         get_page_and_check_success 'two_player_limit'
         
         
         params).should be == (
            {port_number: 18791, match_name: 'default',
               game_definition_file_name: GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker],
               number_of_hands: 1, random_seed: params[:random_seed], player_names: 'user, p2'})
         end
      end
      it 'creates a new Match' do
         pending 'figure out how to validate the Match input'
         
         match = mock('Match')
         Match.stubs(:create).returns(match)
         Match.expects(:create).once.with()
      end
      it 'starts a dealer instance in the background' do
         pending 'Try mocking Stalker.enqueue'
      end
      it 'queries the Match for the port numbers' do
         pending
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
  #
  #describe "GET 'two_player_no_limit'" do
  #  it "should be successful" do
  #    get 'two_player_no_limit'
  #    response.should be_success
  #  end
  #end
  #
  #describe "GET 'three_player_limit'" do
  #  it "should be successful" do
  #    get 'three_player_limit'
  #    response.should be_success
  #  end
  #end
  #
  #describe "GET 'three_player_no_limit'" do
  #  it "should be successful" do
  #    get 'three_player_no_limit'
  #    response.should be_success
  #  end
  #end

end
