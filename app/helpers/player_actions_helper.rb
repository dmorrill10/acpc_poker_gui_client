
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

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view(match_id)
    @match_view ||= MatchView.new(match_id)
    replace_page_contents 'player_actions/index'
  end
  def acting_player_id(player_seat)
    if (
      !match_view.slice.hand_ended? &&
      match_view.slice.seat_next_to_act == player_seat
    )
      'acting_player'
    else
      'not_acting_player'
    end
  end
  def user_must_act?
    (
      !waiting_for_response && (
        (
          @match_view.slice.users_turn_to_act? &&
          @match_view.match.slices.length == 1
        ) ||
        @match_view.slice.hand_ended?
      )
    )
  end
  def next_hand_button_visible?
    @match_view.slice.hand_ended? && !@match_view.slice.match_ended?
  end
  def match_view() @match_view end
  def hotkey_field_tag(name, initial_value='', options={})
    text_field_tag name, initial_value, options.merge(maxlength: 1, size: 1, name: "#{hotkeys_param_key}[#{name}]")
  end

  # @todo Do not require state, remove from this module
  def fold_html_class() 'fold' end
  def pass_html_class() 'pass' end
  def wager_html_class() 'wager' end
  def next_hand_id() 'next_state' end
  def update_id() 'update' end
  def update_state_html_class() 'update_state' end
  def update_hotkeys_html_class() 'update_hotkeys' end
  def leave_match_button_html_class() 'leave-btn' end
  def nav_leave_html_class() 'leave' end
  def leave_match_confirmation_message
    "Are you sure you want to leave this match?"
  end
  def leave_match_label() "Leave Match" end
  def html_character(suit_symbol)
    Suit::DOMAIN[suit_symbol][:html_character]
  end
  def hotkeys_param_key
    'hotkeys'
  end
  def customize_hotkeys_html_id
    'customize_hotkeys'
  end
  def no_change?(action_label, new_key)
    user.hotkeys[action_label] == new_key
  end
  def waiting_for_response
    session[:waiting_for_response]
  end
end