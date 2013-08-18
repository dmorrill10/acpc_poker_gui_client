
# Gems
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/suit'

require File.expand_path('../application_helper', __FILE__)

# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
  include ApplicationHelper
  include AcpcPokerTypes

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view(match_id)
    @match_view ||= MatchView.new(match_id)
    @partial ||= 'player_actions/index'
    replace_page_contents @partial
  end
  def acting_player_id(player_seat)
    if (
      !match_view.hand_ended? &&
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
          @match_view.users_turn_to_act? &&
          @match_view.match.slices.length == 1
        ) ||
        @match_view.hand_ended?
      )
    )
  end
  def next_hand_button_visible?
    !@match_view.match_ended? && @match_view.hand_ended?
  end
  def match_view() @match_view end
  def hotkey_field_tag(name, initial_value='', options={})
    text_field_tag name, initial_value, options.merge(maxlength: 1, size: 1, name: "#{hotkeys_param_key}[#{name}]")
  end

  # Assumes that it will be called right after the corresponding custom_hotkey_amount_field_tag call
  def custom_hotkey_key_field_tag
    text_field_tag "custom_key", '', maxlength: 1, size: 1, name: "#{custom_hotkeys_keys_param_key}[]"
  end

  def custom_hotkey_amount_field_tag
    number_field_tag(
      "custom_amount",
      '',
      maxlength: 4,
      size: 4,
      name: "#{custom_hotkeys_amount_param_key}[]",
      min: 0,
      max: 9999,
      step: 0.01
    )
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
  def custom_hotkeys_amount_param_key
    'custom_hotkeys_amount'
  end
  def custom_hotkeys_keys_param_key
    'custom_hotkeys_key'
  end
  def no_change?(action_label, new_key)
    old_hotkey = user.hotkeys.where(action: action_label).first
    old_hotkey && old_hotkey.key == new_key
  end
  def waiting_for_response
    session['waiting_for_response']
  end

  def wager_disabled_when
    !(
      user_must_act? &&
      (
        match_view.legal_actions.include?(AcpcPokerTypes::PokerAction::RAISE) ||
        match_view.legal_actions.include?(AcpcPokerTypes::PokerAction::BET)
      )
    )
  end
  def fold_disabled_when
    !(
      user_must_act? &&
      match_view.legal_actions.include?(AcpcPokerTypes::PokerAction::FOLD)
    )
  end
  def pass_action_button_label
    if (
      match_view.legal_actions.include?(AcpcPokerTypes::PokerAction::CALL) &&
      match_view.amount_for_next_player_to_call > 0
    )
      if match_view.no_limit?
        "Call (#{match_view.amount_for_next_player_to_call.to_i})"
      else
       'Call'
      end
    else
      'Check'
    end
  end
  def make_wager_button_label
    label = if match_view.legal_actions.include?('b')
      'Bet'
    else
      'Raise'
    end
    label += ' to' if match_view.no_limit?
    label
  end
end