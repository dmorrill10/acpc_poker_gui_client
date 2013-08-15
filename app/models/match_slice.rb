require 'mongoid'

require 'acpc_poker_types/game_definition'

require_relative '../../lib/mongoid_ext/chip_stack'

class MatchSlice
  include Mongoid::Document

  embedded_in :match, inverse_of: :slices

  field :match_has_ended, type: Boolean
  field :seat_with_dealer_button, type: Integer
  field :seat_with_small_blind, type: Integer
  field :seat_with_big_blind, type: Integer
  field :seat_next_to_act, type: Integer
  field :state_string, type: String
  field :balances, type: Array
  field :betting_sequence, type: String

  def self.from_players_at_the_table(patt)
    # @todo thing to do
    raise 'todo'
  end

  def self.betting_sequence(match_state, game_def)
    sequence = ''
    match_state.betting_sequence(game_def).each_with_index do |actions_per_round, round|
      actions_per_round.each_with_index do |action, action_index|
        adjusted_action = adjust_action_amount(
          action,
          round,
          match_state,
          game_def
        )

        sequence << if (
          match_state.player_acting_sequence(game_def)[round][action_index].to_i ==
          match_state.position_relative_to_dealer
        )
          adjusted_action.capitalize
        else
          adjusted_action
        end
      end
      sequence << '/' unless round == match_state.betting_sequence(game_def).length - 1
    end
    sequence
  end

  def self.no_limit?(game_def)
    game_def.betting_type == GameDefinition::BETTING_TYPES[:nolimit]
  end

  def self.pot_at_start_of_round(match_state, game_def)
    return 0 if match_state.round == 0

    match_state.players(game_def).inject(0) do |sum, pl|
      sum += pl.contributions[0..match_state.round - 1].inject(:+)
    end
  end

  # @return [Array<Hash>] Player information ordered by seat.
  # Each player hash should contain
  # values for the following keys:
  # 'name',
  # 'seat'
  # 'chip_stack'
  # 'chip_contributions'
  # 'chip_balance'
  # 'hole_cards'
  # 'winnings'
  def self.players(state, game_def, users_seat, player_names, balances)
    players = []
    rotation_for_seat = state.position_relative_to_dealer - users_seat
    state.players(game_def).rotate(rotation_for_seat).each_with_index do |player, seat|
      hole_cards = if !(player.hand.empty? || player.folded?)
        player.hand.to_s
      elsif player.folded?
        ''
      else
        '_' * game_def.number_of_hole_cards
      end

      players.push(
        'name' => player_names[seat],
        'seat' => seat,
        'chip_stack' => player.stack,
        'chip_contributions' => player.contributions,
        'chip_balance' => balances.rotate(-users_seat)[seat],
        'hole_cards' => hole_cards,
        'winnings' => player.winnings
      )
    end
    players
  end

  # Over round
  def self.minimum_wager_to(state, game_def)
    return 0 unless state.next_to_act(game_def)

    (
      state.min_wager_by(game_def) +
      chip_contribution_after_calling(state, game_def)
    ).ceil
  end

  # Over round
  def self.chip_contribution_after_calling(state, game_def)
    (
      (
        state.players(game_def)[
          state.next_to_act(game_def)
        ].contributions[state.round] || 0
      ) +
      state.players(game_def).amount_to_call(state.next_to_act(game_def))
    )
  end

  # Over round
  def self.pot_after_call(state, game_def)
    return state.pot(game_def) if state.hand_ended?(game_def)

    state.pot(game_def) + state.players(game_def).amount_to_call(state.next_to_act(game_def))
  end

  # Over round
  def self.pot_fraction_wager_to(state, game_def, fraction=1)
    return 0 if state.hand_ended?(game_def)

    [
      [
        (
          fraction * pot_after_call(state, game_def) +
          chip_contribution_after_calling(state, game_def)
        ),
        minimum_wager_to(state, game_def)
      ].max,
      all_in(state, game_def)
    ].min.floor
  end

  # Over round
  def self.all_in(state, game_def)
    return 0 if state.hand_ended?(game_def)

    (
      state.players(game_def)[state.next_to_act(game_def)].stack +
      (
        state.players(game_def)[state.next_to_act(game_def)]
          .contributions[state.round] || 0
      )
    ).floor
  end



  def match_ended?
    match_has_ended
  end

  private

  def self.adjust_action_amount(action, round, match_state, game_def)
    amount_to_over_hand = action.modifier
    if amount_to_over_hand.blank?
      action
    else
      amount_to_over_round = (
        amount_to_over_hand.to_i - match_state.players(game_def)[
          match_state.position_relative_to_dealer
        ].contributions_before(round).to_i
      )
      "#{action[0]}#{amount_to_over_round}"
    end
  end
end