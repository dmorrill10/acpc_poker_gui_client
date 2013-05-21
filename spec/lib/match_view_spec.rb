require_relative '../spec_helper'

require 'acpc_poker_types/match_state'

require 'match_view'

describe MatchView do
  before do
    match_id = 'match ID'
    @x_match = mock 'Match'
    Match.expects(:find).with(match_id).returns(@x_match)
    @patient = MatchView.new(match_id)
    @patient.match.should be @x_match
  end
  it '#state works' do
    state_string = "#{AcpcPokerTypes::MatchState::LABEL}:0:0::AhKs|"
    slice = mock('MatchSlice')
    @x_match.expects(:slices).returns([slice])
    slice.expects(:state_string).returns(state_string)
    @patient.state.should == AcpcPokerTypes::MatchState.new(state_string)
  end
  describe '#pot_at_start_of_round' do
    it 'works after the first round' do
      slice = mock('MatchSlice')
      @x_match.expects(:slices).returns([slice])
      x_contribution_in_first_round = 10
      players = [
        {'chip_contributions' => [x_contribution_in_first_round, 15]},
        {'chip_contributions' => [x_contribution_in_first_round, 0]}
      ]
      slice.expects(:players).returns(players)
      @patient.pot_at_start_of_round.should == 2*x_contribution_in_first_round
    end
    it 'works in the first round' do
      slice = mock('MatchSlice')
      @x_match.expects(:slices).returns([slice])
      x_contribution_in_first_round = 10
      players = [
        {'chip_contributions' => [x_contribution_in_first_round]},
        {'chip_contributions' => [x_contribution_in_first_round/2]}
      ]
      slice.expects(:players).returns(players)
      @patient.pot_at_start_of_round.should == 0
    end
  end
  it '#no_limit? works' do
    {
      AcpcPokerTypes::GameDefinition::BETTING_TYPES[:limit] => false,
      AcpcPokerTypes::GameDefinition::BETTING_TYPES[:nolimit] => true
    }.each do |type, x_is_no_limit|
      @x_match.expects(:betting_type).returns(type)
      @patient.no_limit?.should == x_is_no_limit
    end
  end
  it '#user works' do
    @x_match.expects(:seat).returns(2)
    slice = mock('MatchSlice')
    @x_match.expects(:slices).returns([slice])
    x_user = {'name' => 'user'}
    players = [
      {'name' => 'opponent1'},
      x_user,
      {'name' => 'opponent2'}
    ]
    slice.expects(:players).returns(players)
    @patient.user.should be x_user
  end
end