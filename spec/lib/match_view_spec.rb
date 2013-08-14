require_relative '../spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

require 'match_view'

module MapWithIndex
  refine Array do
    def map_with_index
      i = 0
      map do |elem|
        result = yield elem, i
        i += 1
        result
      end
    end
  end
end
using MapWithIndex

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
      x_game_def = GameDefinition.new(
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
      )
      @x_match.expects(:game_def).returns(x_game_def)

      patient.game_def.to_h.should == x_game_def.to_h
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

      @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
      patient.no_limit?.should == x_is_no_limit
      @patient = nil
    end
  end
  it '#betting_sequence works' do
    game_def = GameDefinition.new(
      first_player_positions: [3, 2, 2, 2],
      chip_stacks: [200, 200, 200],
      blinds: [10, 0, 5],
      raise_sizes: [10]*4,
      number_of_ranks: 3
    )
    @x_match.expects(:game_def).returns(game_def)
    slice = mock('MatchSlice')
    @x_match.expects(:slices).returns([slice])
    slice.expects(:state_string).returns("#{MatchState::LABEL}:1:0:ccr20cc/r50fr100c/cc/cc:AhKs||")
    @patient.betting_sequence.should == 'ckR20cc/B30fr80C/Kk/Kk'
  end
  describe '#pot_at_start_of_round' do
    it 'works after each round' do
      game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [200, 200, 200],
        blinds: [10, 0, 5],
        raise_sizes: [10]*4,
        number_of_ranks: 3
      )
      betting_sequence = [['c', 'c', 'r20', 'c', 'c'], ['r50', 'f', 'r100', 'c'], ['c', 'c'], ['c', 'c']]
      betting_sequence_string = ''
      x_contributionx_at_start_of_round = [0, 60, 220, 220]

      betting_sequence.each_with_index do |actions_per_round, round|
        betting_sequence_string << '/' unless round == 0
        actions_per_round.each do |action|
          betting_sequence_string << action
          match_state = "#{MatchState::LABEL}:1:0:#{betting_sequence_string}:AhKs||"

          slice = mock('MatchSlice')
          slice.expects(:state_string).returns(match_state)
          @x_match.expects(:game_def).returns(game_def) unless round == 0
          @x_match.expects(:slices).returns([slice])

          patient.pot_at_start_of_round.should == x_contributionx_at_start_of_round[round]
          @patient = nil
        end
      end
    end
  end
  describe '#players, #user, and #opponents' do
    it 'work' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [500, 450, 550],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3,
        number_of_hole_cards: 1
      }
      game_def = GameDefinition.new(x_game_def)
      x_actions = [
        [
          [
            PokerAction.new(PokerAction::RAISE, cost: wager_size + 10),
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::FOLD)
          ]
        ],
        [
          [
            PokerAction.new(PokerAction::CALL, cost: wager_size)
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::BET, cost: wager_size)
          ]
        ],
        [
          [
            PokerAction.new(PokerAction::CALL, cost: 5),
            PokerAction.new(PokerAction::CALL, cost: wager_size)
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::RAISE, cost: 2 * wager_size)
          ]
        ]
      ]

      x_player_names = ['opponent0', 'user', 'opponent2']

      (0..game_def.number_of_players-1).each do |position|
        slice = mock('MatchSlice')
        @x_match.expects(:slices).returns([slice])
        @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
        seat = 1
        @x_match.expects(:seat).returns(seat + 1)
        @x_match.expects(:player_names).returns(x_player_names)

        hands = []
        hands << Hand.new
        hands << Hand.new(['']*game_def.number_of_hole_cards)
        hands << Hand.new(['']*game_def.number_of_hole_cards)
        hands[position] = arbitrary_hole_card_hand unless hands[position].empty?

        hands_for_string = hands.dup
        hands_for_string[position] = arbitrary_hole_card_hand
        hand_string = hands_for_string.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        x_contributions = x_actions.rotate(position - seat).map_with_index do |actions_per_player, i|
          player_contribs = actions_per_player.map do |actions_per_round|
            actions_per_round.inject(0) { |sum, action| sum += action.cost }
          end
          player_contribs[0] += game_def.blinds.rotate(position - seat)[i]
          player_contribs
        end

        x_stacks = game_def.chip_stacks.rotate(position - seat).map_with_index do |chip_stack, i|
          chip_stack - x_contributions[i].inject(:+)
        end

        match_state =
          "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrf:#{hand_string}"
        slice.expects(:state_string).returns(match_state)

        x_balances = x_contributions.map { |contrib| -contrib.inject(:+) }
        slice.expects(:balances).returns(x_balances.rotate(seat))

        x_players = [
          {
            'name' => x_player_names[0],
            'seat' => 0,
            'chip_stack' => x_stacks[0],
            'chip_contributions' => x_contributions[0],
            'chip_balance' => x_balances[0],
            'hole_cards' => hands.rotate(position - seat)[0]
          },
          {
            'name' => x_player_names[1],
            'seat' => 1,
            'chip_stack' => x_stacks[1],
            'chip_contributions' => x_contributions[1],
            'chip_balance' => x_balances[1],
            'hole_cards' => hands[position]
          },
          {
            'name' => x_player_names[2],
            'seat' => 2,
            'chip_stack' => x_stacks[2],
            'chip_contributions' => x_contributions[2],
            'chip_balance' => x_balances[2],
            'hole_cards' => hands.rotate(position - seat)[2]
          }
        ]

        patient.players.should == x_players
        patient.user.should == x_players[seat]
        patient.opponents.should === -> { opp = x_players.dup; opp.delete_at(seat); opp }.call
        @patient = nil
      end
    end
  end
  describe '#minimum_wager_to' do
    it 'works' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_min_wagers = [
        [2*wager_size],
        [2*wager_size, 50, 170, 170, wager_size],
        [wager_size, wager_size, wager_size],
        [wager_size, 2*wager_size, 50, 90, 90]
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"

            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.minimum_wager_to.should == x_min_wagers[i][j]
            @patient = nil
          end
        end
      end
    end
  end
  describe '#pot' do
    it 'works' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [500, 600, 550],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_pot = [
        [15],
        [
          15 + 10,
          15 + 30,
          30 + 10 + 100,
          200 + 30,
          300
        ],
        [300] * 3,
        [
          300,
          310,
          110 + 130 + 100,
          160 + 130 + 110,
          160 * 2 + 130
        ]
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot.should == x_pot[i][j]
            @patient = nil
          end
        end
      end
    end
  end
  describe '#pot_after_call' do
    it 'works' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [500, 600, 550],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_pot = [
        [15 + 10],
        [
          15 + 10,
          30 * 2 + 10,
          100 * 2 + 30,
          300,
          300
        ],
        [
          300,
          300,
          300
        ],
        [
          300,
          310 + 10,
          110 * 3 + 20 * 2,
          160 * 3 - 30,
          160 * 3
        ]
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_after_call.should == x_pot[i][j]
            @patient = nil
          end
        end
      end
    end
  end
  describe '#pot_fraction_wager_to' do
    it 'provides the pot wager to amount without an argument' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 6000, 5500],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_pot_fraction_wager_to = [
        [15 + 10 + 10],
        [
          30 + 10,
          70 + 30,
          30 + 100 + 100 + 100,
          300 + 100,
          300
        ],
        [300]*3,
        [
          100 * 3, # after 'cr30r100cc/ccc/c'
          110 * 2 + 100 + 10, # after 'cr30r100cc/ccc/cr110'
          130 * 2 + 110 + 30, # after 'cr30r100cc/ccc/cr110r130'
          160 * 2 + 130 + 60, # after 'cr30r100cc/ccc/cr110r130r160'
          160 * 3 + 60 # after 'cr30r100cc/ccc/cr110r130r160c'
        ]
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_fraction_wager_to.should == x_pot_fraction_wager_to[i][j]
            @patient = nil
          end
        end
      end
    end
    it 'provides a half pot wager to amount when given 0.5' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 6000, 5500],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_pot_fraction_wager_to = [
        [(15 + 10)/2.0 + 10],
        [
          30/2.0 + 10,
          70/2.0 + 30,
          (30 + 100 + 100)/2.0 + 100,
          300/2.0 + 100,
          300/2.0
        ],
        [300/2.0]*3,
        [
          (100 * 3)/2.0, # after 'cr30r100cc/ccc/c'
          (110 * 2 + 100)/2.0 + 10, # after 'cr30r100cc/ccc/cr110'
          (130 * 2 + 110)/2.0 + 30, # after 'cr30r100cc/ccc/cr110r130'
          (160 * 2 + 130)/2.0 + 60, # after 'cr30r100cc/ccc/cr110r130r160'
          (160 * 3)/2.0 + 60 # after 'cr30r100cc/ccc/cr110r130r160c'
        ]
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_fraction_wager_to(0.5).should == x_pot_fraction_wager_to[i][j].floor
            @patient = nil
          end
        end
      end
    end
  end
  describe '#all_in' do
    it 'works' do
      wager_size = 10
      x_game_def = {
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 5000, 5000],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      }
      game_def = GameDefinition.new(x_game_def)

      x_all_in = [
        [5000],
        [5000]*4 << 4900,
        [4900]*3,
        [4900]*5
      ]

      hands = game_def.number_of_players.times.map { |i| Hand.new }

      hand_string = hands.inject('') do |string, hand|
        string << "#{hand}#{MatchState::HAND_SEPARATOR}"
      end[0..-2]

      (0..game_def.number_of_players-1).each do |position|
        [
          [''],
          ['c', 'cr30', 'cr30r100', 'cr30r100c', 'cr30r100cc/'],
          ['cr30r100cc/c', 'cr30r100cc/cc', 'cr30r100cc/ccc/'],
          [
            'cr30r100cc/ccc/c',
            'cr30r100cc/ccc/cr110',
            'cr30r100cc/ccc/cr110r130',
            'cr30r100cc/ccc/cr110r130r160',
            'cr30r100cc/ccc/cr110r130r160c'
          ]
        ].each_with_index do |betting_sequence_list, i|
          betting_sequence_list.each_with_index do |betting_sequence, j|
            match_state = "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            slice = mock('MatchSlice')
            slice.expects(:state_string).returns(match_state)
            @x_match.expects(:game_def).returns(GameDefinition.new(x_game_def))
            @x_match.expects(:slices).returns([slice])

            patient.all_in.should == x_all_in[i][j].floor
            @patient = nil
          end
        end
      end
    end
  end
end

def arbitrary_hole_card_hand
  Hand.from_acpc('2s3h')
end