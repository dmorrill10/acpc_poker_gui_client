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
  it '#acting_player works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:seat_next_to_act).returns(2)
    x_player_next_to_act = {'name' => 'opponent2'}
    players = [
      {'name' => 'opponent1'},
      {'name' => 'user'},
      x_player_next_to_act
    ]
    slice.stubs(:players).returns(players)

    @patient.next_player_to_act.should == x_player_next_to_act
  end
  it '#minimum_wager_to works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:seat_next_to_act).returns(2)
    minimum_wager = 5
    slice.expects(:minimum_wager).returns(minimum_wager)
    contribution_in_first_round = 10
    amount_to_call = 15
    players = [
      {
        'name' => 'opponent1',
        'amount_to_call' => 0,
        'chip_contributions' => [contribution_in_first_round/2],
        'chip_stack' => 2000
      },
      {
        'name' => 'user',
        'amount_to_call' => 0,
        'chip_contributions' => [contribution_in_first_round/2],
        'chip_stack' => 2000
      },
      {
        'name' => 'opponent2',
        'amount_to_call' => amount_to_call,
        'chip_contributions' => [contribution_in_first_round],
        'chip_stack' => 2000
      }
    ]
    slice.stubs(:players).returns(players)
    @patient.minimum_wager_to.should == minimum_wager + amount_to_call + contribution_in_first_round
  end
  it '#pot works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:seat_next_to_act).returns(2)
    contribution_in_first_round = 10
    players = [
      {'name' => 'opponent1', 'chip_contributions' => [contribution_in_first_round/2]},
      {'name' => 'user', 'chip_contributions' => [contribution_in_first_round/2]},
      {'name' => 'opponent2', 'chip_contributions' => [contribution_in_first_round]}
    ]
    slice.stubs(:players).returns(players)
    @patient.pot.should == contribution_in_first_round * 2
  end
  it '#pot_after_call works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:seat_next_to_act).returns(2)
    contribution_in_first_round = 10
    amount_to_call = 15
    players = [
      {'name' => 'opponent1', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2]},
      {'name' => 'user', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2]},
      {'name' => 'opponent2', 'amount_to_call' => amount_to_call, 'chip_contributions' => [contribution_in_first_round]}
    ]
    slice.stubs(:players).returns(players)
    @patient.pot_after_call.should == contribution_in_first_round * 2 + amount_to_call
  end
  describe '#pot_fraction_wager_to' do
    it 'provides the pot wager to amount without an argument' do
      slice = mock('MatchSlice')
      minimum_wager = 5
      slice.expects(:minimum_wager).returns(minimum_wager)
      @x_match.stubs(:slices).returns([slice])
      slice.stubs(:seat_next_to_act).returns(2)
      contribution_in_first_round = 10
      amount_to_call = 15
      players = [
        {'name' => 'opponent1', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
        {'name' => 'user', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
        {'name' => 'opponent2', 'amount_to_call' => amount_to_call, 'chip_contributions' => [contribution_in_first_round], 'chip_stack' => 2000}
      ]
      slice.stubs(:players).returns(players)
      @patient.pot_fraction_wager_to.should ==(
        contribution_in_first_round * 2 + amount_to_call +
        contribution_in_first_round + amount_to_call
      )
    end
    it 'works for different fractions' do
      [1/2.to_f, 3/4.to_f, 1, 2].each do |fraction|
        slice = mock('MatchSlice')
        minimum_wager = 5
        slice.expects(:minimum_wager).returns(minimum_wager)
        @x_match.stubs(:slices).returns([slice])
        slice.stubs(:seat_next_to_act).returns(2)
        contribution_in_first_round = 10
        amount_to_call = 15
        players = [
          {'name' => 'opponent1', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
          {'name' => 'user', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
          {'name' => 'opponent2', 'amount_to_call' => amount_to_call, 'chip_contributions' => [contribution_in_first_round], 'chip_stack' => 2000}
        ]
        slice.stubs(:players).returns(players)
        @patient.pot_fraction_wager_to(fraction).should ==(
          fraction *
          (contribution_in_first_round * 2 + amount_to_call) +
          contribution_in_first_round + amount_to_call
        )
      end
    end
  end
  it '#all_in works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:seat_next_to_act).returns(2)
    contribution_in_first_round = 10
    chip_stack = 2000
    players = [
      {
        'name' => 'opponent1',
        'amount_to_call' => 0,
        'chip_contributions' => [contribution_in_first_round]
      },
      {
        'name' => 'opponent2',
        'amount_to_call' => 0,
        'chip_contributions' => [contribution_in_first_round]
      },
      {
        'name' => 'user',
        'amount_to_call' => contribution_in_first_round/2,
        'chip_contributions' => [contribution_in_first_round/2],
        'chip_stack' => chip_stack - contribution_in_first_round/2
      }
    ]
    slice.stubs(:players).returns(players)
    @patient.all_in.should == chip_stack
  end
  it '#betting_sequence works' do
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.stubs(:betting_sequence).returns('ccr15cc/b50fr100c/kk/kk')
    @x_match.stubs(:seat).returns(2)
    players = [
      {
        'name' => 'opponent1',
        'chip_contributions' => [15, 85, 0, 0]
      },
      {
        'name' => 'user',
        'chip_contributions' => [15, 0, 0, 0]
      },
      {
        'name' => 'opponent2',
        'chip_contributions' => [15, 85, 0, 0]
      }
    ]
    slice.stubs(:players).returns(players)
    slice.stubs(:player_acting_sequence).returns(
      '20120/0120/02/02'
    )
    @patient.betting_sequence.should == 'ccR15cc/b35Fr85c/kk/kk'
  end
end