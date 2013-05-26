
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
    {class: (classes + ['poker_actn_btn']), id: ids, name: ids, disabled: disabled_when, data: { disable_with: label }}
  end
  def poker_action_submission(label, disabled_when, classes=[], ids=[])
    submit_tag label, poker_action_submission_options(label, disabled_when, classes + ['hidden'], ids)
  end
  def update_state_form(match_id, submit_button_label='', button_options={})
    button_options[:id] = 'update_match_state' unless button_options[:id]
    form_tag update_match_state_url, :remote => true do
      form = hidden_match_fields match_id
      form << submit_tag(submit_button_label, button_options)
    end
  end
  def check_update_state_form(match_id, submit_button_label='', button_options={})
    button_options[:id] = 'check update_match_state' unless button_options[:id]
    form_tag check_update_match_state_url, :remote => true do
      form = hidden_match_fields match_id
      form << submit_tag(submit_button_label, button_options)
    end
  end

  def poker_action_form(action, label, disabled_when, classes=[], ids=[])
    form_for @user_poker_action, url: take_action_url, remote: true do |f|
      form = f.hidden_field :match_id, value: @match_id
      form << f.hidden_field(:poker_action, value: action)
      form << poker_action_submission(label, disabled_when, classes, ids)
      form << yield(f) if block_given?
      form
    end
  end

  def hidden_match_fields(match_id)
    form = hidden_field_tag(:match_id, match_id, id: 'match_id_hidden_field')
  end

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view
    @user_poker_action = UserPokerAction.new
    @match_view ||= MatchView.new(@match_id)
    replace_page_contents 'player_actions/index'
  end

  def html_character(suit_symbol)
    Suit::DOMAIN[suit_symbol][:html_character]
  end

  def acting_player_id(player_seat)
    if (
      !@match_view.slice.hand_ended? &&
      @match_view.slice.seat_next_to_act == player_seat
    )
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

  # Updates the current match state.
  def update_match!
    @match_id ||= params[:match_id]
    assert_new_match_state

    self
  end
  def new_match_state?(match)
    puts "   NUM SLICES: #{match.slices.length}"
    match.slices.length > 0
  end
  def assert_new_match_state
    looping_condition = ->(proc_match) { !new_match_state?(proc_match) }
    @match_view = MatchView.failsafe_while_for_match @match_id, looping_condition do
      # @todo Log here
      # @todo Maybe use a processing spinner
    end
  end
end
