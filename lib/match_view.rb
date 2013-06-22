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
    if round > 0
      player['chip_contributions'][0..round-1].inject(:+)
    else
      0
    end
  end
  def self.chip_contribution_after_calling(player)
    player['chip_contributions'].inject(:+) + player['amount_to_call']
  end
  def user_contributions_in_previous_rounds(
    round = user['chip_contributions'].length - 1
  )
    MatchView.chip_contributions_in_previous_rounds(user, round)
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
      if player['hole_cards'].nil? || player['hole_cards'].kind_of?(AcpcPokerTypes::Hand)
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
  # zero indexed
  def users_seat
    @match.seat - 1
  end
  def user
    players[users_seat]
  end
  def opponents
    opp = players.dup
    opp.delete_at(users_seat)
    opp
  end
  def next_player_to_act
    ap _ID: @match.id, _SLICES: @match.slices if slice.nil?
    if slice.seat_next_to_act
      players[slice.seat_next_to_act]
    end
  end
  # Over round
  def minimum_wager_to
    return 0 unless next_player_to_act
    [
      slice.minimum_wager +
      next_player_to_act['amount_to_call'] +
      next_player_to_act['chip_contributions'].last,
      all_in
    ].min.round
  end
  def pot
    players.inject(0) { |sum, player| sum += player['chip_contributions'].inject(:+) }
  end
  def pot_after_call
    pot + if next_player_to_act
      next_player_to_act['amount_to_call']
    else
      0
    end
  end
  # Over round
  def pot_fraction_wager_to(fraction=1)
    return 0 unless next_player_to_act
    [
      [
        (
          fraction * pot_after_call +
          next_player_to_act['chip_contributions'].last +
          next_player_to_act['amount_to_call']
        ),
        minimum_wager_to
      ].max,
      all_in
    ].min.round
  end
  # Over round
  def all_in
    return 0 unless next_player_to_act
    (
      next_player_to_act['chip_stack'] +
      next_player_to_act['chip_contributions'].last
    ).round
  end
  # Over round
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