
# Gems
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/suit'
require 'acpc_poker_match_state'

require File.expand_path('../application_helper', __FILE__)

# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
  include ApplicationHelper

  def update_state_form(match_id, match_slice_index, submit_button_label='', button_options={})
    button_options[:class] = 'button'
    button_options[:id] = 'update_match_state' unless button_options[:id]
    form_tag update_game_state_url, :remote => true do
      form = hidden_match_fields match_id, match_slice_index
      form << submit_tag(submit_button_label, button_options)
    end
  end

  def hidden_check_for_new_match_state_form(match_id, match_slice_index)
    form_tag check_for_new_match_state_url, remote: true do
      form = hidden_match_fields match_id, match_slice_index
      form << submit_tag('Check for new match state', id: 'check_for_new_match_state', style: 'visibility: hidden')
    end
  end

  def hidden_match_fields(match_id, match_slice_index)
    form = hidden_field_tag(:match_id, match_id, id: 'match_id_hidden_field')
    form << hidden_field_tag(:match_slice_index, match_slice_index, id: 'match_slice_index_hidden_field')
  end

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view
    @user_poker_action = UserPokerAction.new
    setup_match_view!
    replace_page_contents 'player_actions/index'
  end

  def html_character(suit_symbol)
    Suit::DOMAIN[suit_symbol][:html_character]
  end

  def setup_match_view!
    @match_state = MatchState.new @match_slice.state_string

    @hand_number = @match_state.hand_number
    @match_name = @match.parameters[:match_name]
    @last_action = @match_state.last_action
    @legal_actions = @match_slice.legal_actions
    @hand_ended = @match_slice.hand_ended?
    @match_ended = @match_slice.match_ended?
    @users_turn_to_act = @match_slice.users_turn_to_act?

    @pot_values_at_start_of_round = @match_slice.pot_values_at_start_of_round
    @round = @match_state.round

    @player_whose_turn_is_next = @match_slice.player_turn_information['whose_turn_is_next']
    @player_with_the_dealer_button = @match_slice.player_turn_information['with_the_dealer_button']
    @player_who_submitted_big_blind = @match_slice.player_turn_information['submitted_big_blind']
    @player_who_submitted_small_blind = @match_slice.player_turn_information['submitted_small_blind']

    setup_board_cards!
    setup_player_information!
    setup_betting_and_acting_sequence!

    delete_match!(@match_id) if @match_ended
  end

  def setup_board_cards!
    @board_cards = @match_state.board_cards
  end

  def setup_betting_and_acting_sequence!
    @action_summary = ""
    if @match_slice.betting_sequence && @match_slice.player_acting_sequence
      i = 0
      @match_slice.betting_sequence.scan(/.\d*/).each do |action|
        @action_summary += if @match_slice.player_acting_sequence[i].to_i == @user['seat']
          action.capitalize
        else
          action
        end
        i += 1
      end
    end
  end

  def setup_pot_information!(players)
    # @todo This becomes more complicated in multi-player
    players.each do |player|
      player['chip_contributions'] = [] unless player['chip_contributions']
      player['chip_contributions'][@round] = 0 unless player['chip_contributions'].length > @round
    end

    @amount_for_user_to_call = @match_slice.amounts_to_call[@user['name']]
    @minimum_wager = @match_slice.minimum_wager + @amount_for_user_to_call + @user['chip_contributions'][@round]

    wager_pot_above_current_round_contribution = players.map do |player|
      player['chip_contributions']
    end.mapped_sum.sum + @amount_for_user_to_call

    current_round_contribution = @user['chip_contributions'][@round]

    @half_pot_wager_amount = [
      (0.50 * wager_pot_above_current_round_contribution).floor +
        current_round_contribution + @amount_for_user_to_call,
      @minimum_wager
    ].max

    @three_quarter_pot_wager_amount = [
      (0.75 * wager_pot_above_current_round_contribution).floor +
        current_round_contribution  + @amount_for_user_to_call,
      @minimum_wager
    ].max

    @pot_wager_amount = [
      wager_pot_above_current_round_contribution + current_round_contribution + 
        @amount_for_user_to_call,
      @minimum_wager
    ].max


    @two_pot_wager_amount = [
      (2 * wager_pot_above_current_round_contribution) +
        current_round_contribution  + @amount_for_user_to_call,
      @minimum_wager
    ].max

    @all_in_amount = @user['chip_stack'] + current_round_contribution

    @amount_user_has_contributed_over_previous_rounds =
      @user['chip_contributions'].sum - current_round_contribution
  end

  def setup_chip_balances!(players)
    @chip_balances = players.inject({}) do |balances, player|
      balances[player['name']] = player['chip_balance']
      balances
    end
  end

  def setup_user_and_opponents!(players)
    failsafe_while(lambda{ !@betting_type }) do
      @match = current_match @match_id
      @betting_type = @match.betting_type
    end
    @is_no_limit = @betting_type == GameDefinition::BETTING_TYPES[:nolimit]

    number_of_hole_cards = @match.number_of_hole_cards

    @opponents = players.dup
    @user = @opponents.delete_at(@match.seat.to_i - 1)
    @opponents.each do |opponent|
      opponent['hole_cards'] = if opponent['hole_cards'].empty?
        (0..number_of_hole_cards-1).inject(Hand.new) { |hand, i| hand << '' }
      else
        Hand.from_acpc opponent['hole_cards']
      end
    end

    @user['hole_cards'] = Hand.from_acpc @user['hole_cards']

    players.each do |player|
      player['hole_cards'] = Hand.new if player['folded?']
    end
  end

  def setup_player_information!
    @players = @match_slice.players

    setup_chip_balances! @players
    setup_user_and_opponents! @players
    setup_pot_information! @players
  end

  def acting_player_id(player_name)
    if !@hand_ended && @player_whose_turn_is_next == player_name
      'acting_player'
    else
      'not_acting_player'
    end
  end

  def delete_match!(match_id)
    begin
      match = current_match(match_id)
    rescue
    else
      match.delete
    end
  end

  # Updates the current match state.
  def update_match!
    @match_slice_index = params[:match_slice_index].to_i || 0
    @match_id = params[:match_id]
    update_match_slice!
  end

  def update_match_slice!
    if new_match_state_available?
      @match = current_match @match_id

      # @todo Ensure that an array out of bounds error from here is handled gracefully
      @match_slice = @match.slices[@match_slice_index]
      @match_slice_index += 1 - @match.delete_previous_slices!(@match_slice_index)
    else
      nil
    end
  end

  def new_match_state?(match)
    match.slices.length > @match_slice_index
  end

  def new_match_state_available?
    match = current_match @match_id
    looping_condition = lambda{ |proc_match| !new_match_state?(proc_match) }
    begin
      match = failsafe_while_for_match @match_id, looping_condition do
        # @todo Log here
        # @todo Maybe use a processing spinner
      end
    rescue
      return false
    end
    true
  end

  def round_specific_sequence(sequence, round)
    return '' if sequence.empty?
    sequence.split(/\//)[round]
  end
end
