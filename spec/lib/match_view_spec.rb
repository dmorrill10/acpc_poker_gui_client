require_relative '../spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

require 'match_view'

include AcpcPokerTypes

describe MatchView do
  before do
    @match_id = 'match ID'
    @x_match = mock 'Match'
    patient.match.should be @x_match
  end
  def patient
    @patient ||= -> do
      Match.expects(:find).with(@match_id).returns(@x_match)
      MatchView.new(@match_id)
    end.call
  end
  describe '#game_def' do
    it 'works' do
      x_game_def = {
        :betting_type => 'nolimit',
        :number_of_players => 2,
        :number_of_rounds => 4,
        :blinds => [10, 5],
        :chip_stacks => [(2147483647/1), (2147483647/1)],
        :raise_sizes => [10, 10, 20, 20],
        :first_player_positions => [1, 0, 0, 0],
        :max_number_of_wagers => [3, 4, 4, 4],
        :number_of_suits => 4,
        :number_of_ranks => 13,
        :number_of_hole_cards => 2,
        :number_of_board_cards => [0, 3, 1, 1]
      }
      @x_match.expects(:game_def).returns(x_game_def)

      patient.game_def.to_h.should == x_game_def
    end
  end
  it '#state works' do
    state_string = "#{MatchState::LABEL}:0:0::AhKs|"
    slice = mock('MatchSlice')
    @x_match.expects(:slices).returns([slice])
    slice.expects(:state_string).returns(state_string)
    patient.state.should == MatchState.new(state_string)
  end
  it '#no_limit? works' do
    {
      GameDefinition::BETTING_TYPES[:limit] => false,
      GameDefinition::BETTING_TYPES[:nolimit] => true
    }.each do |type, x_is_no_limit|

      x_game_def = {
        :betting_type => type
      }

      @x_match.expects(:game_def).returns(x_game_def)
      patient.no_limit?.should == x_is_no_limit
      @patient = nil
    end
  end
  it '#betting_sequence works' do
    game_def = {
      first_player_positions: [3, 2, 2, 2],
      chip_stacks: [200, 200, 200],
      blinds: [10, 0, 5],
      raise_sizes: [10]*4,
      number_of_ranks: 3
    }
    @x_match.expects(:game_def).returns(game_def)
    slice = mock('MatchSlice')
    @x_match.stubs(:slices).returns([slice])
    slice.expects(:state_string).returns("#{MatchState::LABEL}:1:0:ccr20cc/r50fr100c/cc/cc:AhKs||")
    @patient.betting_sequence.should == 'ckR20cc/B30fr80C/Kk/Kk'
  end
  describe '#pot_at_start_of_round' do
    it 'works after each round' do
      game_def = {
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [200, 200, 200],
        blinds: [10, 0, 5],
        raise_sizes: [10]*4,
        number_of_ranks: 3
      }
      betting_sequence = [['c', 'c', 'r20', 'c', 'c'], ['r50', 'f', 'r100', 'c'], ['c', 'c'], ['c', 'c']]
      betting_sequence_string = ''
      x_contributionx_at_start_of_round = [15, 60, 220, 220]

      betting_sequence.each_with_index do |actions_per_round, round|
        betting_sequence_string << '/' unless round == 0
        actions_per_round.each do |action|
          betting_sequence_string << action
          match_state = "#{MatchState::LABEL}:1:0:#{betting_sequence_string}:AhKs||"

          slice = mock('MatchSlice')
          slice.expects(:state_string).returns(match_state)
          @x_match.expects(:game_def).returns(game_def)
          @x_match.expects(:slices).returns([slice])

          patient.pot_at_start_of_round.should == x_contributionx_at_start_of_round[round]
          @patient = nil
        end
      end
    end
  end
  # it '#user works' do
  #   @x_match.expects(:seat).returns(2)
  #   slice = mock('MatchSlice')
  #   @x_match.expects(:slices).returns([slice])
  #   x_user = {'name' => 'user'}
  #   players = [
  #     {'name' => 'opponent1'},
  #     x_user,
  #     {'name' => 'opponent2'}
  #   ]
  #   slice.expects(:players).returns(players)
  #
  # end
  # describe '#players' do
  #   it 'works in general' do
  #     slice = mock('MatchSlice')
  #     @x_match.expects(:slices).returns([slice])
  #     x_players = [
  #       {'name' => 'opponent1'},
  #       {'name' => 'user'},
  #       {'name' => 'opponent2'}
  #     ]
  #     slice.expects(:players).returns(x_players)
  #
  # end
  # it '#opponents works' do
  #   @x_match.stubs(:seat).returns(2)
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   x_opponents = [
  #     {'name' => 'opponent1'},
  #     {'name' => 'opponent2'}
  #   ]
  #   players = [
  #     x_opponents[0],
  #     {'name' => 'user'},
  #     x_opponents[1]
  #   ]
  #   slice.stubs(:players).returns(players)
  #
  # end
  # it '#acting_player works' do
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   slice.stubs(:seat_next_to_act).returns(2)
  #   x_player_next_to_act = {'name' => 'opponent2'}
  #   players = [
  #     {'name' => 'opponent1'},
  #     {'name' => 'user'},
  #     x_player_next_to_act
  #   ]
  #   slice.stubs(:players).returns(players)

  #
  # end
  # it '#minimum_wager_to works' do
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   slice.stubs(:seat_next_to_act).returns(2)
  #   minimum_wager = 5
  #   slice.expects(:minimum_wager).returns(minimum_wager)
  #   contribution_in_first_round = 10
  #   amount_to_call = 15
  #   players = [
  #     {
  #       'name' => 'opponent1',
  #       'amount_to_call' => 0,
  #       'chip_contributions' => [contribution_in_first_round/2],
  #       'chip_stack' => 2000
  #     },
  #     {
  #       'name' => 'user',
  #       'amount_to_call' => 0,
  #       'chip_contributions' => [contribution_in_first_round/2],
  #       'chip_stack' => 2000
  #     },
  #     {
  #       'name' => 'opponent2',
  #       'amount_to_call' => amount_to_call,
  #       'chip_contributions' => [contribution_in_first_round],
  #       'chip_stack' => 2000
  #     }
  #   ]
  #   slice.stubs(:players).returns(players)
  #
  # end
  # it '#pot works' do
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   slice.stubs(:seat_next_to_act).returns(2)
  #   contribution_in_first_round = 10
  #   players = [
  #     {'name' => 'opponent1', 'chip_contributions' => [contribution_in_first_round/2]},
  #     {'name' => 'user', 'chip_contributions' => [contribution_in_first_round/2]},
  #     {'name' => 'opponent2', 'chip_contributions' => [contribution_in_first_round]}
  #   ]
  #   slice.stubs(:players).returns(players)
  #
  # end
  # it '#pot_after_call works' do
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   slice.stubs(:seat_next_to_act).returns(2)
  #   contribution_in_first_round = 10
  #   amount_to_call = 15
  #   players = [
  #     {'name' => 'opponent1', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2]},
  #     {'name' => 'user', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2]},
  #     {'name' => 'opponent2', 'amount_to_call' => amount_to_call, 'chip_contributions' => [contribution_in_first_round]}
  #   ]
  #   slice.stubs(:players).returns(players)
  #
  # end
  # describe '#pot_fraction_wager_to' do
  #   it 'provides the pot wager to amount without an argument' do
  #     slice = mock('MatchSlice')
  #     minimum_wager = 5
  #     slice.expects(:minimum_wager).returns(minimum_wager)
  #     @x_match.stubs(:slices).returns([slice])
  #     slice.stubs(:seat_next_to_act).returns(2)
  #     contribution_in_first_round = 10
  #     amount_to_call = 15
  #     players = [
  #       {'name' => 'opponent1', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
  #       {'name' => 'user', 'amount_to_call' => 0, 'chip_contributions' => [contribution_in_first_round/2], 'chip_stack' => 2000},
  #       {'name' => 'opponent2', 'amount_to_call' => amount_to_call, 'chip_contributions' => [contribution_in_first_round], 'chip_stack' => 2000}
  #     ]
  #     slice.stubs(:players).returns(players)
  #
  # end
  # it '#all_in works' do
  #   slice = mock('MatchSlice')
  #   @x_match.stubs(:slices).returns([slice])
  #   slice.stubs(:seat_next_to_act).returns(2)
  #   contribution_in_first_round = 10
  #   chip_stack = 2000
  #   players = [
  #     {
  #       'name' => 'opponent1',
  #       'amount_to_call' => 0,
  #       'chip_contributions' => [contribution_in_first_round]
  #     },
  #     {
  #       'name' => 'opponent2',
  #       'amount_to_call' => 0,
  #       'chip_contributions' => [contribution_in_first_round]
  #     },
  #     {
  #       'name' => 'user',
  #       'amount_to_call' => contribution_in_first_round/2,
  #       'chip_contributions' => [contribution_in_first_round/2],
  #       'chip_stack' => chip_stack - contribution_in_first_round/2
  #     }
  #   ]
  #   slice.stubs(:players).returns(players)
  #
  # end
end