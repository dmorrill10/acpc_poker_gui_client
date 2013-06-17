
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
    {class: classes, id: ids, name: ids, disabled: disabled_when, data: { disable_with: label }}
  end
  def poker_action_form(action, label, disabled_when, classes=[], ids=[])
    form_tag(match_home_url, poker_action_submission_options(label, disabled_when, classes, ids).merge({remote: true})) do
      form = hidden_match_fields
      form << hidden_field_tag(:poker_action, action)
      form << hidden_field_tag(:modifier)
      form << button_tag(label, poker_action_submission_options(label, disabled_when, classes, ids))
      form << yield(form) if block_given?
      form
    end
  end

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view(match_id)
    @match_view ||= MatchView.new(match_id)
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
end
