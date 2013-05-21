
# Gems
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/suit'
require 'acpc_poker_match_state'

require File.expand_path('../application_helper', __FILE__)

# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
  include ApplicationHelper
  include AcpcPokerTypes

  def poker_action_submission_options(label, disabled_when, classes=[], ids=[], link=nil)
    {class: (classes + ['btn', 'btn-primary', 'btn-block', 'poker_action_button']), id: ids, name: ids, disabled: disabled_when, data: { disable_with: label }}
  end
  def poker_action_submission(label, disabled_when, classes=[], ids=[])
    submit_tag label, poker_action_submission_options(label, disabled_when, classes + ['hidden'], ids)
  end
  def update_state_form(match_id, match_slice_index, submit_button_label='', button_options={})
    button_options[:id] = 'update_match_state' unless button_options[:id]
    form_tag update_match_state_url, :remote => true do
      form = hidden_match_fields match_id, match_slice_index
      form << submit_tag(submit_button_label, button_options)
    end
  end

  def poker_action_form(action, label, disabled_when, classes=[], ids=[])
    form_for @user_poker_action, url: take_action_url, remote: true, validate: true do |f|
      form = f.hidden_field :match_id, value: @match_id
      form << f.hidden_field(:match_slice_index, value: @match_slice_index)
      form << f.hidden_field(:poker_action, value: action)
      form << poker_action_submission(label, disabled_when, classes, ids)
      form << yield(f) if block_given?
      form
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

    @pot_at_start_of_round = @match_slice.players.inject(0) do |sum, player|
      sum += if @match_state.round > 0
        player['chip_contributions'][0..@match_state.round-1].inject(:+)
      else
        0
      end
    end


    setup_player_information!
    setup_betting_and_acting_sequence!
    Match.delete_match!(@match_id) if @match_slice.match_ended?
  end

  def setup_betting_and_acting_sequence!
    @action_summary = ""
    if @match_slice.betting_sequence && @match_slice.player_acting_sequence
      i = 0
      # @todo Adjust amounts to 'wager-to over round' from 'wager-to over hand'
      @match_slice.betting_sequence.scan(/.\d*/).each do |action|
        @action_summary << if @match_slice.player_acting_sequence[i].to_i == @user['seat']
          action.capitalize
        else
          action
        end
        i += 1
      end
    end
    self
  end

  def setup_pot_information!(players)
    # @todo Is this still needed?
    players.each do |player|
      player['chip_contributions'] = [0] unless player['chip_contributions']
      player['chip_contributions'][@match_state.round] = 0 unless player['chip_contributions'].length > @match_state.round
    end

    # @todo A lot of these variables should be methods instead. No need to copy them
    @minimum_wager = @match_slice.minimum_wager + @user['amount_to_call'] +
      @user['chip_contributions'][@match_state.round]

    wager_pot_above_current_round_contribution = players.map do |player|
      player['chip_contributions'].inject(:+)
    end.inject(:+) + @user['amount_to_call']

    current_round_contribution = @user['chip_contributions'][@match_state.round]

    @half_pot_wager_amount = [
      (0.50 * wager_pot_above_current_round_contribution).floor +
        current_round_contribution + @user['amount_to_call'],
      @minimum_wager
    ].max

    @three_quarter_pot_wager_amount = [
      (0.75 * wager_pot_above_current_round_contribution).floor +
        current_round_contribution  + @user['amount_to_call'],
      @minimum_wager
    ].max

    @pot_wager_amount = [
      wager_pot_above_current_round_contribution + current_round_contribution +
        @user['amount_to_call'],
      @minimum_wager
    ].max

    @two_pot_wager_amount = [
      (2 * wager_pot_above_current_round_contribution) +
        current_round_contribution  + @user['amount_to_call'],
      @minimum_wager
    ].max

    @all_in_amount = @user['chip_stack'] + current_round_contribution

    @amount_user_has_contributed_over_previous_rounds =
      @user['chip_contributions'].sum - current_round_contribution

    self
  end

  def setup_user_and_opponents!(players)
    # @todo This should be a method
    @is_no_limit = @match.betting_type == GameDefinition::BETTING_TYPES[:nolimit]

    # @todo These should be methods rather than copies
    @opponents = players.dup
    @user = @opponents.delete_at(@match.seat.to_i - 1)

    # @todo Clean this up
    @opponents.each do |opponent|
      opponent['hole_cards'] = if opponent['hole_cards'].empty?
        (0..@match.number_of_hole_cards-1).inject(Hand.new) { |hand, i| hand << '' }
      else
        Hand.from_acpc opponent['hole_cards']
      end
    end

    @user['hole_cards'] = Hand.from_acpc @user['hole_cards']

    players.each do |player|
      # @todo Can this be replaced with #from_acpc?
      player['hole_cards'] = Hand.new if player['folded?']
    end

    self
  end

  def setup_player_information!
    setup_user_and_opponents! @match_slice.players
    setup_pot_information! @match_slice.players
  end

  def acting_player_id(player_seat)
    if !@match_slice.hand_ended? && @match_slice.seat_next_to_act == player_seat
      'acting_player'
    else
      'not_acting_player'
    end
  end

  def next_hand_id
    'next_state'
  end

  def leave_match_id
    'match_ended_leave'
  end

  def leave_match_confirmation_message
    "Are you sure you want to leave this match?"
  end

  def leave_match_label
    "Leave Match"
  end

  # @todo This should return self
  # Updates the current match state.
  def update_match!
    @match_slice_index = params[:match_slice_index].to_i || 0
    @match_id = params[:match_id]
    update_match_slice!
  end

  # @todo This should return self
  def update_match_slice!
    if new_match_state_available?
      @match = Match.find @match_id

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
    match = Match.find @match_id
    looping_condition = lambda{ |proc_match| !new_match_state?(proc_match) }
    begin
      match = Match.failsafe_while_for_match @match_id, looping_condition do
        # @todo Log here
        # @todo Maybe use a processing spinner
      end
    rescue
      return false
    end
    true
  end
end
