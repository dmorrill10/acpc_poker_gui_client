require_relative '../spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

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
  describe '#players' do
    it 'works in general' do
      slice = mock('MatchSlice')
      @x_match.expects(:slices).returns([slice])
      x_players = [
        {'name' => 'opponent1'},
        {'name' => 'user'},
        {'name' => 'opponent2'}
      ]
      slice.expects(:players).returns(x_players)
      @patient.players.map{|player| player['name']}.should == x_players.map{|player| player['name']}
    end
    it 'provides cards to players' do
      slice = mock('MatchSlice')
      @x_match.expects(:slices).returns([slice])
      x_hole_cards = 'AhKs'
      players = [
        {'name' => 'opponent1', 'folded?' => false, 'hole_cards' => ''},
        {'name' => 'user', 'folded?' => false, 'hole_cards' => x_hole_cards},
        {'name' => 'opponent2', 'folded?' => true, 'hole_cards' => x_hole_cards}
      ]
      slice.expects(:players).returns(players)
      number_of_hole_cards = 2
      @x_match.expects(:number_of_hole_cards).returns(number_of_hole_cards)
      x_players = [
        players[0].merge({'hole_cards' => AcpcPokerTypes::Hand.new(['']*number_of_hole_cards)}),
        players[1].merge({'hole_cards' => AcpcPokerTypes::Hand.from_acpc(x_hole_cards)}),
        players[2].merge({'hole_cards' => AcpcPokerTypes::Hand.new})
      ]
      @patient.players.should == x_players
    end
  end
  it '#opponents works' do
    @x_match.stubs(:seat).returns(2)
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    x_opponents = [
      {'name' => 'opponent1'},
      {'name' => 'opponent2'}
    ]
    players = [
      x_opponents[0],
      {'name' => 'user'},
      x_opponents[1]
    ]
    slice.stubs(:players).returns(players)
    @patient.opponents.should == x_opponents
  end
end