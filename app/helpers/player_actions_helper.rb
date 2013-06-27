
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
      (
        @match_view.slice.users_turn_to_act? &&
        @match_view.match.slices.length == 1
      ) ||
      @match_view.slice.hand_ended?
    )
  end
  def next_hand_button_visible?
    @match_view.slice.hand_ended? && !@match_view.slice.match_ended?
  end
  def match_view() @match_view end
  def match() match_view.match end
  def hotkey_field_tag(name, initial_value='', options={})
    text_field_tag name, initial_value, options.merge(maxlength: 1, size: 1, name: "#{hotkeys_param_key}[#{name}]")
  end
  def min_wager_hotkey
    match_view.match.hotkeys[Match::MIN_WAGER_LABEL]
  end
  def all_in_hotkey
    match_view.match.hotkeys[Match::ALL_IN_WAGER_LABEL]
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
  def pot_fraction_label(pot_fraction)
    if pot_fraction == 1
      'Pot'
    else
      "#{pot_fraction}xPot"
    end
  end
  def hotkeys_param_key
    'hotkeys'
  end
  def customize_hotkeys_html_id
    'customize_hotkeys'
  end
  def no_change?(action_label, new_key)
    match.hotkeys[action_label]['key'] == new_key
  end
  # @todo Remove
  # Thanks to http://stackoverflow.com/questions/5490952/merge-array-of-hashes-to-get-hash-of-arrays-of-values for this
  # def collect_values(hashes)
  #   {}.tap{ |r| hashes.each{ |h| h.each{ |k,v| r[k] = v } } }
  # end
end
