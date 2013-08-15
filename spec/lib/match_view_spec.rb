require_relative '../spec_helper'

require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'
require_relative '../../lib/application_defs'

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
      @x_match.expects(:no_limit?).returns(x_is_no_limit)
      patient.no_limit?.should == x_is_no_limit
      @patient = nil
    end
  end
  describe '#pot_fraction_wager_to' do
    it 'provides the pot wager to amount without an argument' do
      wager_size = 10
      game_def = GameDefinition.new(
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 6000, 5500],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      )

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
            match_state = MatchState.parse(
              "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            )
            slice = mock('MatchSlice')
            slice.expects(:hand_ended?).returns(false)
            slice.expects(:pot_after_call).returns(MatchSlice.pot_after_call(match_state, game_def))
            slice.expects(:minimum_wager_to).returns(MatchSlice.minimum_wager_to(match_state, game_def))
            slice.expects(:chip_contribution_after_calling).returns(
              MatchSlice.chip_contribution_after_calling(match_state, game_def)
            )
            slice.expects(:all_in).returns(MatchSlice.all_in(match_state, game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_fraction_wager_to.should == x_pot_fraction_wager_to[i][j]
            @patient = nil
          end
        end
      end
    end
    it 'provides a half pot wager to amount when given 0.5' do
      wager_size = 10
      game_def = GameDefinition.new(
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 6000, 5500],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      )

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
            match_state = MatchState.parse(
              "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            )
            slice = mock('MatchSlice')
            slice.expects(:hand_ended?).returns(false)
            slice.expects(:pot_after_call).returns(MatchSlice.pot_after_call(match_state, game_def))
            slice.expects(:minimum_wager_to).returns(MatchSlice.minimum_wager_to(match_state, game_def))
            slice.expects(:chip_contribution_after_calling).returns(
              MatchSlice.chip_contribution_after_calling(match_state, game_def)
            )
            slice.expects(:all_in).returns(MatchSlice.all_in(match_state, game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_fraction_wager_to(0.5).should == x_pot_fraction_wager_to[i][j].floor
            @patient = nil
          end
        end
      end
    end
    it 'provides a two pot wager to amount when given 2' do
      wager_size = 10
      game_def = GameDefinition.new(
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 6000, 5500],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      )

      x_pot_fraction_wager_to = [
        [(15 + 10)*2.0 + 10],
        [
          30*2.0 + 10,
          70*2.0 + 30,
          (30 + 100 + 100)*2.0 + 100,
          300*2.0 + 100,
          300*2.0
        ],
        [300*2.0]*3,
        [
          (100 * 3)*2.0, # after 'cr30r100cc/ccc/c'
          (110 * 2 + 100)*2.0 + 10, # after 'cr30r100cc/ccc/cr110'
          (130 * 2 + 110)*2.0 + 30, # after 'cr30r100cc/ccc/cr110r130'
          (160 * 2 + 130)*2.0 + 60, # after 'cr30r100cc/ccc/cr110r130r160'
          (160 * 3)*2.0 + 60 # after 'cr30r100cc/ccc/cr110r130r160c'
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
            match_state = MatchState.parse(
              "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            )
            slice = mock('MatchSlice')
            slice.expects(:hand_ended?).returns(false)
            slice.expects(:pot_after_call).returns(MatchSlice.pot_after_call(match_state, game_def))
            slice.expects(:minimum_wager_to).returns(MatchSlice.minimum_wager_to(match_state, game_def))
            slice.expects(:chip_contribution_after_calling).returns(
              MatchSlice.chip_contribution_after_calling(match_state, game_def)
            )
            slice.expects(:all_in).returns(MatchSlice.all_in(match_state, game_def))
            @x_match.expects(:slices).returns([slice])

            patient.pot_fraction_wager_to(2).should == x_pot_fraction_wager_to[i][j].floor
            @patient = nil
          end
        end
      end
    end
    it 'provides all common fractions correctly for a particular state' do
      game_def = GameDefinition.parse_file(ApplicationDefs::STATIC_GAME_DEFINITIONS[:two_player_nolimit][:file])
      match_state = MatchState.parse "MATCHSTATE:1:1:cc/r200c/c:|Qs8d/Qd7s9d/Ac"

      slice = mock('MatchSlice')
      slice.expects(:hand_ended?).returns(false)
      slice.expects(:pot_after_call).returns(MatchSlice.pot_after_call(match_state, game_def))
      slice.expects(:minimum_wager_to).returns(MatchSlice.minimum_wager_to(match_state, game_def))
      slice.expects(:chip_contribution_after_calling).returns(
        MatchSlice.chip_contribution_after_calling(match_state, game_def)
      )
      slice.expects(:all_in).returns(MatchSlice.all_in(match_state, game_def))
      @x_match.expects(:slices).returns([slice])

      patient.pot_fraction_wager_to(0.5).should == 200
      patient.pot_fraction_wager_to(0.75).should == 300
      patient.pot_fraction_wager_to.should == 400
      patient.pot_fraction_wager_to(2).should == 800
    end
  end
  describe '#all_in' do
    it 'works' do
      wager_size = 10
      game_def = GameDefinition.new(
        first_player_positions: [0, 0, 0],
        chip_stacks: [5000, 5000, 5000],
        blinds: [0, 5, 10],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      )

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
            match_state = MatchState.parse(
              "#{MatchState::LABEL}:#{position}:0:#{betting_sequence}:#{hand_string}"
            )
            slice = mock('MatchSlice')
            slice.expects(:all_in).returns(MatchSlice.all_in(match_state, game_def))
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