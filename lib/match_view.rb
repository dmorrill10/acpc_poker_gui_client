
require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

class MatchView
  include AcpcPokerTypes
  attr_reader :match

  def self.chip_contributions_in_previous_rounds(player, round)
    if round > 0
      player['chip_contributions'][0..round-1].inject(:+)
    else
      0
    end
  end

  def initialize(match_id)
    @match = Match.find(match_id)
  end
  def user_contributions_in_previous_rounds
    self.class.chip_contributions_in_previous_rounds(user, state.round)
  end
  def state
    @state ||= MatchState.parse slice.state_string
  end
  def slice
    @slice ||= @match.slices.first
  end
  def player_names
    @player_names ||= @match.player_names
  end
  # zero indexed
  def users_seat
    @users_seat ||= @match.seat - 1
  end
  def balances
    @balances ||= slice.balances
  end
  def no_limit?
    @is_no_limit ||= @match.no_limit?
  end
  def game_def
    @game_def ||= @match.game_def
  end
  def betting_sequence
    @betting_sequence ||= slice.betting_sequence
  end
  def pot_at_start_of_round
    @pot_at_start_of_round ||= slice.pot_at_start_of_round
  end
  def hand_ended?
    @hand_has_ended = slice.hand_ended? if @hand_has_ended.nil?

    @hand_has_ended
  end
  def match_ended?
    @match_has_ended = slice.match_ended? if @match_has_ended.nil?

    @match_has_ended
  end
  def users_turn_to_act?
    @is_users_turn_to_act = slice.users_turn_to_act? if @is_users_turn_to_act.nil?

    @is_users_turn_to_act
  end
  def legal_actions
    @legal_actions ||= slice.legal_actions.map { |action| AcpcPokerTypes::PokerAction.new(action) }
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
  def players
    return @players if @players

    @players = slice.players
  end
  def user
    @user ||= players[users_seat]
  end
  def opponents
    @opponents ||= compute_opponents
  end
  def opponents_sorted_by_position_from_user
    @opponents_sorted_by_position_from_user ||= opponents.sort_by do |opp|
      Seat.new(
        opp['seat'],
        players.length
      ).seats_from(
        users_seat
      )
    end
  end
  def amount_for_next_player_to_call
    @amount_for_next_player_to_call ||= slice.amount_to_call
  end

  # Over round
  def chip_contribution_for_next_player_after_calling
    @chip_contribution_for_next_player_after_calling ||= slice.chip_contribution_after_calling
  end

  # Over round
  def minimum_wager_to
    @minimum_wager_to ||= slice.minimum_wager_to
  end

  # Over round
  def pot_after_call
    @pot_after_call ||= slice.pot_after_call
  end

  # Over round
  def pot_fraction_wager_to(fraction=1)
    return 0 if hand_ended?

    [
      [
        (
          fraction * pot_after_call +
          chip_contribution_for_next_player_after_calling
        ),
        minimum_wager_to
      ].max,
      all_in
    ].min.floor
  end

  # Over round
  def all_in
    @all_in ||= slice.all_in
  end

  def betting_type_label
    if @betting_type_label.nil?
      @betting_type_label = if no_limit?
        'nolimit'
      else
       'limit'
      end
    end

    @betting_type_label
  end

  private

  def compute_opponents
    opp = players.dup
    opp.delete_at(users_seat)
    opp
  end
end