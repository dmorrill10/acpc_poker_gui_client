require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

class MatchView
  attr_reader :match

  def initialize(match_id)
    @match = Match.find(match_id)
  end
  def state
    AcpcPokerTypes::MatchState.parse slice.state_string
  end
  def slice
    @match.slices.first
  end
  def self.chip_contributions_in_previous_rounds(
    player,
    round = player['chip_contributions'].length - 1
  )
    if player['chip_contributions'].length > 1
      player['chip_contributions'][0..round-1].inject(:+)
    else
      0
    end
  end
  def self.chip_contribution_after_calling(player)
    player['chip_contributions'].inject(:+) + player['amount_to_call']
  end
  def pot_at_start_of_round
    slice.players.inject(0) do |sum, player|
      sum += MatchView.chip_contributions_in_previous_rounds(player)
    end
  end
  def no_limit?
    @match.betting_type == AcpcPokerTypes::GameDefinition::BETTING_TYPES[:nolimit]
  end
  def players
    slice.players.map do |player|
      if player['hole_cards'].nil?
        # Do nothing
      elsif player['folded?']
        player['hole_cards'] = AcpcPokerTypes::Hand.new
      elsif player['hole_cards'].empty?
        player['hole_cards'] = AcpcPokerTypes::Hand.new(['']*@match.number_of_hole_cards)
      else
        player['hole_cards'] = AcpcPokerTypes::Hand.from_acpc(player['hole_cards'])
      end
      player
    end
  end
  def user
    players[@match.seat - 1]
  end
  def opponents
    opp = players.dup
    opp.delete_at(@match.seat-1)
    opp
  end
  def next_player_to_act
    if slice.seat_next_to_act
      players[slice.seat_next_to_act - 1]
    end
  end
  def minimum_wager_to
    slice.minimum_wager + next_player_to_act['amount_to_call'] +
      next_player_to_act['chip_contributions'].inject(:+)
  end
  def pot
    players.inject(0) { |sum, player| sum += player['chip_contributions'].inject(:+) }
  end
  def pot_after_call
    pot + next_player_to_act['amount_to_call']
  end
  def pot_fraction_wager_to(fraction=1)
    [
      (
        fraction * pot_after_call +
        MatchView.chip_contribution_after_calling(next_player_to_act)
      ),
      minimum_wager_to
    ].max
  end
  def all_in
    next_player_to_act['chip_stack'] +
    MatchView.chip_contribution_after_calling(next_player_to_act)
  end
  def betting_sequence
    sequence = ''
    round = 0
    slice.betting_sequence.scan(/.\d*/)
      .each_with_index do |action, action_index|
      round += 1 if action == '/'
      action = adjust_action_amount action, round, action_index

      sequence << if slice.player_acting_sequence[action_index].to_i == @match.seat-1
        action.capitalize
      else
        action
      end
    end
    sequence
  end

  private

  def adjust_action_amount(action, round, action_index)
    amount_to_over_hand = action[1..-1]
    if amount_to_over_hand.empty?
      action
    else
      # @todo This is broken
      puts "round: #{round}"
      amount_to_over_round = (
        amount_to_over_hand.to_i -
        MatchView.chip_contributions_in_previous_rounds(
          players[slice.player_acting_sequence[action_index].to_i],
          round
        )
      )
      "#{action[0]}#{amount_to_over_round}"
    end
  end
end