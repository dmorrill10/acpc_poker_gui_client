require_relative '../spec_helper'

require 'acpc_poker_types/match_state'
include AcpcPokerTypes

class Match
  def self.delete_match!(id)
    self
  end
end

describe PlayerActionsHelper do
  describe '#setup_match_view' do
    it 'works given an initial match state of a hand' do
      pending 'Not needed until WAPP tests are finished'
      x_match_state = MatchState.new "#{MatchState::LABEL}:0:0::Ah2c|"
      x_legal_actions = [PokerAction::CHECK, PokerAction::RAISE]
      x_hand_ended = false
      x_match_ended = false
      x_users_turn_to_act = false
      x_pot_values_at_start_of_round = [0]

    # @todo Fill in player hashes
      x_player_whose_turn_is_next = []
      @match_slice.player_turn_information['whose_turn_is_next']
    @player_with_the_dealer_button = @match_slice.player_turn_information['with_the_dealer_button']
    @player_who_submitted_big_blind = @match_slice.player_turn_information['submitted_big_blind']
    @player_who_submitted_small_blind = @match_slice.player_turn_information['submitted_small_blind']

      @match_slice = Struct.new(
        :state_string,
        :legal_actions,
        :hand_ended?,
        :match_ended?,
        :users_turn_to_act?,
        :pot_values_at_start_of_round,
        :player_turn_information
      ).new(
        x_match_state.to_s,
        x_legal_actions,
        x_hand_ended,
        x_match_ended,
        x_users_turn_to_act,
        x_pot_values_at_start_of_round,

      )
      x_hand_number = x_match_state.hand_number
      x_last_action = x_match_state.last_action
      x_round = x_match_state.round
      x_board_cards = x_match_state.board_cards

      x_match_name = 'match name'
      @match = Struct.new(:parameters).new({match_name: x_match_name})


# @todo Add checks for all this stuff
  #   @action_summary = ""
  #   if @match_slice.betting_sequence && @match_slice.player_acting_sequence
  #     i = 0
  #     @match_slice.betting_sequence.scan(/.\d*/).each do |action|
  #       @action_summary << if @match_slice.player_acting_sequence[i].to_i == @user['seat']
  #         action.capitalize
  #       else
  #         action
  #       end
  #       i += 1
  #     end
  #   end
  # end

  # def setup_pot_information!(players)
  #   # @todo This becomes more complicated in multi-player
  #   players.each do |player|
  #     player['chip_contributions'] = [[0]] unless player['chip_contributions']
  #     player['chip_contributions'][@round] = 0 unless player['chip_contributions'].length > @round
  #   end

  #   @amount_for_user_to_call = @match_slice.amounts_to_call[@user['name']]
  #   @minimum_wager = @match_slice.minimum_wager + @amount_for_user_to_call + @user['chip_contributions'][@round]

  #   wager_pot_above_current_round_contribution = players.map do |player|
  #     player['chip_contributions']
  #   end.mapped_sum.sum + @amount_for_user_to_call

  #   current_round_contribution = @user['chip_contributions'][@round]

  #   @half_pot_wager_amount = [
  #     (0.50 * wager_pot_above_current_round_contribution).floor +
  #       current_round_contribution + @amount_for_user_to_call,
  #     @minimum_wager
  #   ].max

  #   @three_quarter_pot_wager_amount = [
  #     (0.75 * wager_pot_above_current_round_contribution).floor +
  #       current_round_contribution  + @amount_for_user_to_call,
  #     @minimum_wager
  #   ].max

  #   @pot_wager_amount = [
  #     wager_pot_above_current_round_contribution + current_round_contribution +
  #       @amount_for_user_to_call,
  #     @minimum_wager
  #   ].max


  #   @two_pot_wager_amount = [
  #     (2 * wager_pot_above_current_round_contribution) +
  #       current_round_contribution  + @amount_for_user_to_call,
  #     @minimum_wager
  #   ].max

  #   @all_in_amount = @user['chip_stack'] + current_round_contribution

  #   @amount_user_has_contributed_over_previous_rounds =
  #     @user['chip_contributions'].sum - current_round_contribution
  # end

  # def setup_chip_balances!(players)
  #   @chip_balances = players.inject({}) do |balances, player|
  #     balances[player['name']] = player['chip_balance']
  #     balances
  #   end
  # end

  # def setup_user_and_opponents!(players)
  #   Match.failsafe_while(lambda{ !@betting_type }) do
  #     @match = Match.find @match_id
  #     @betting_type = @match.betting_type
  #   end
  #   @is_no_limit = @betting_type == GameDefinition::BETTING_TYPES[:nolimit]

  #   number_of_hole_cards = @match.number_of_hole_cards

  #   @opponents = players.dup
  #   @user = @opponents.delete_at(@match.seat.to_i - 1)
  #   @opponents.each do |opponent|
  #     opponent['hole_cards'] = if opponent['hole_cards'].empty?
  #       (0..number_of_hole_cards-1).inject(Hand.new) { |hand, i| hand << '' }
  #     else
  #       Hand.from_acpc opponent['hole_cards']
  #     end
  #   end

  #   @user['hole_cards'] = Hand.from_acpc @user['hole_cards']

  #   players.each do |player|
  #     player['hole_cards'] = Hand.new if player['folded?']
  #   end
  # end

  # def setup_player_information!
  #   @players = @match_slice.players

  #   setup_chip_balances! @players
  #   setup_user_and_opponents! @players
  #   setup_pot_information! @players


    end
    it 'works given a match state from the middle of a hand' do
    end
    it 'works given the last match state of a hand, but not at the end of the match' do
    end
    it 'works given the last match state of the match' do
    end
  end
end