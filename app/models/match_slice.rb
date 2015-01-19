require 'mongoid'

require 'acpc_poker_types/game_definition'

class MatchSlice
  include Mongoid::Document

  embedded_in :match, inverse_of: :slices

  field :hand_has_ended, type: Boolean
  field :match_has_ended, type: Boolean
  field :seat_with_dealer_button, type: Integer
  field :seat_next_to_act, type: Integer
  field :state_string, type: String
  # Not necessary to be in the database, but more performant than processing on the
  # Rails server
  field :betting_sequence, type: String
  field :pot_at_start_of_round, type: Integer
  field :players, type: Array
  field :minimum_wager_to, type: Integer
  field :chip_contribution_after_calling, type: Integer
  field :pot_after_call, type: Integer
  field :is_users_turn_to_act, type: Boolean
  field :legal_actions, type: Array
  field :amount_to_call, type: Integer
  field :messages, type: Array

  def self.from_players_at_the_table!(patt, match_has_ended, match)
    match.slices.create!(
      hand_has_ended: patt.hand_ended?,
      match_has_ended: match_has_ended,
      seat_with_dealer_button: patt.dealer_player.seat.to_i,
      seat_next_to_act: if patt.next_player_to_act
        patt.next_player_to_act.seat.to_i
      end,
      state_string: patt.match_state.to_s,
      # Not necessary to be in the database, but more performant than processing on the
      # Rails server
      betting_sequence: betting_sequence(patt.match_state, patt.game_def),
      pot_at_start_of_round: pot_at_start_of_round(patt.match_state, patt.game_def).to_i,
      players: players(patt, match.player_names),
      minimum_wager_to: minimum_wager_to(patt.match_state, patt.game_def).to_i,
      chip_contribution_after_calling: chip_contribution_after_calling(patt.match_state, patt.game_def).to_i,
      pot_after_call: pot_after_call(patt.match_state, patt.game_def).to_i,
      all_in: all_in(patt.match_state, patt.game_def).to_i,
      is_users_turn_to_act: patt.users_turn_to_act?,
      legal_actions: patt.legal_actions.map { |action| action.to_s },
      amount_to_call: amount_to_call(patt.match_state, patt.game_def).to_i
    )
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
  def self.players(patt, player_names)
    player_names_queue = player_names.dup
    patt.players.map do |player|
      hole_cards = if !(player.hand.empty? || player.folded?)
        player.hand.to_acpc
      elsif player.folded?
        ''
      else
        '_' * patt.game_def.number_of_hole_cards
      end

      {
        'name' => player_names_queue.shift,
        'seat' => player.seat,
        'chip_stack' => player.stack.to_i,
        'chip_contributions' => player.contributions.map { |contrib| contrib.to_i },
        'chip_balance' => player.balance,
        'hole_cards' => hole_cards,
        'winnings' => player.winnings.to_f
      }
    end
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
    return 0 unless state.next_to_act(game_def)

    (
      (
        state.players(game_def)[
          state.next_to_act(game_def)
        ].contributions[state.round] || 0
      ) + amount_to_call(state, game_def)
    )
  end

  # Over round
  def self.pot_after_call(state, game_def)
    return state.pot(game_def) if state.hand_ended?(game_def)

    state.pot(game_def) + state.players(game_def).amount_to_call(state.next_to_act(game_def))
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

  def self.amount_to_call(state, game_def)
    return 0 if state.next_to_act(game_def).nil?

    state.players(game_def).amount_to_call(state.next_to_act(game_def))
  end

  def users_turn_to_act?
    self.is_users_turn_to_act
  end
  def hand_ended?
    self.hand_has_ended
  end
  def match_ended?
    self.match_has_ended
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