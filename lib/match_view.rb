require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

class MatchView
  include AcpcPokerTypes
  attr_reader :match

  def self.chip_contributions_in_previous_rounds(
    player,
    round = player.contributions.length - 1
  )
    if round > 0
      player.contributions[0..round-1].inject(:+)
    else
      0
    end
  end

  def initialize(match_id)
    @match = Match.find(match_id)
  end
  def state
    @state ||= MatchState.parse slice.state_string
  end
  def slice
    @slice ||= @match.slices.first
  end
  def no_limit?
    game_def.betting_type == GameDefinition::BETTING_TYPES[:nolimit]
  end
  def game_def
    @game_def ||= GameDefinition.new(@match.game_def)
  end
  def betting_sequence
    sequence = ''
    state.betting_sequence(game_def).each_with_index do |actions_per_round, round|
      actions_per_round.each_with_index do |action, action_index|
        action = adjust_action_amount action, round, action_index

        sequence << if (
          state.player_acting_sequence(game_def)[round][action_index].to_i ==
          state.position_relative_to_dealer
        )
          action.capitalize
        else
          action
        end
      end
      sequence << '/' unless round == state.betting_sequence(game_def).length - 1
    end
    sequence
  end
  def pot_at_start_of_round
    if state.round == 0
      game_def.blinds.inject(:+)
    else
      state.players(game_def).inject(0) { |sum, pl| sum += pl.contributions[0..state.round - 1].inject(:+) }
    end
  end

  # def self.chip_contribution_after_calling(player)
  #   player['chip_contributions'].inject(:+) + player['amount_to_call']
  # end
  # def user_contributions_in_previous_rounds(
  #   round = user['chip_contributions'].length - 1
  # )
  #   MatchView.chip_contributions_in_previous_rounds(user, round)
  # end

  # def players
  #   slice.players.map do |player|
  #     if player['hole_cards'].nil? || player['hole_cards'].kind_of?(Hand)
  #       # Do nothing
  #     elsif player['folded?']
  #       player['hole_cards'] = Hand.new
  #     elsif player['hole_cards'].empty?
  #       player['hole_cards'] = Hand.new(['']*@match.number_of_hole_cards)
  #     else
  #       player['hole_cards'] = Hand.from_acpc(player['hole_cards'])
  #     end
  #     player
  #   end
  # end
  # # zero indexed
  # def users_seat
  #   @match.seat - 1
  # end
  # def user
  #   players[users_seat]
  # end
  # def opponents
  #   opp = players.dup
  #   opp.delete_at(users_seat)
  #   opp
  # end
  # def next_player_to_act
  #   ap _ID: @match.id, _SLICES: @match.slices if slice.nil?
  #   if slice.seat_next_to_act
  #     players[slice.seat_next_to_act]
  #   end
  # end
  # # Over round
  # def minimum_wager_to
  #   return 0 unless next_player_to_act
  #   [
  #     slice.minimum_wager +
  #     next_player_to_act['amount_to_call'] +
  #     next_player_to_act['chip_contributions'].last,
  #     all_in
  #   ].min.round
  # end
  # def pot
  #   players.inject(0) { |sum, player| sum += player['chip_contributions'].inject(:+) }
  # end
  # def pot_after_call
  #   pot + if next_player_to_act
  #     next_player_to_act['amount_to_call']
  #   else
  #     0
  #   end
  # end
  # # Over round
  # def pot_fraction_wager_to(fraction=1)
  #   return 0 unless next_player_to_act
  #   [
  #     [
  #       (
  #         fraction * pot_after_call +
  #         next_player_to_act['chip_contributions'].last +
  #         next_player_to_act['amount_to_call']
  #       ),
  #       minimum_wager_to
  #     ].max,
  #     all_in
  #   ].min.round
  # end
  # # Over round
  # def all_in
  #   return 0 unless next_player_to_act
  #   (
  #     next_player_to_act['chip_stack'] +
  #     next_player_to_act['chip_contributions'].last
  #   ).round
  # end
  # Over round

  private

  def adjust_action_amount(action, round, action_index)
    amount_to_over_hand = action.modifier
    if amount_to_over_hand.blank?
      action
    else
      amount_to_over_round = (
        amount_to_over_hand.to_i - MatchView.chip_contributions_in_previous_rounds(
          state.players(game_def)[state.position_relative_to_dealer],
          round
        ).to_i
      )
      "#{action[0]}#{amount_to_over_round}"
    end
  end
end