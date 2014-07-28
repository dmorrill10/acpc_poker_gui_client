# Local modules
require 'application_defs'
require 'application_helper'
require 'acpc_poker_types/seat'
require 'match'
require 'user'
require 'hotkey'

require 'ap'

class MatchViewManagerController < ApplicationController
  include ApplicationHelper
  include PlayerActionsHelper
  helper_method(
    :match_view,
    :stale_slice?,
    :player_role_id,
    :user_must_act?,
    :next_hand_button_visible?,
    :wager_disabled_when,
    :fold_disabled_when,
    :pass_action_button_label,
    :make_wager_button_label
  )
  protected

  def match_view() @match_view end

  def stale_slice?
    match_slice_index < (match_view.slices.length - 1)
  end

  def player_role_id(player_seat)
    if (
      !match_view.hand_ended? &&
      match_view.slice.seat_next_to_act == player_seat
    )
      PlayerActionsHelper::ACTOR_ID
    else
      PlayerActionsHelper::PLAYER_NOT_ACTING_ID
    end
  end

  def user_must_act?
    match_view.users_turn_to_act? || match_view.hand_ended?
  end
  def next_hand_button_visible?
    !match_view.match_ended? && match_view.hand_ended?
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
        "#{PlayerActionsHelper::CALL_LABEL} (#{match_view.amount_for_next_player_to_call.to_i})"
      else
       PlayerActionsHelper::CALL_LABEL
      end
    else
      PlayerActionsHelper::CHECK_LABEL
    end
  end
  def make_wager_button_label
    label = if match_view.legal_actions.include?('b')
      PlayerActionsHelper::BET_LABEL
    else
      PlayerActionsHelper::RAISE_LABEL
    end
    label += ' to' if match_view.no_limit?
    label
  end
end

# Controller for the main game view where the table and actions are presented to the player.
# Implements the actions in the main match view.
class PlayerActionsController < MatchViewManagerController
  def index
    return reset_to_match_entry_view(
      "Sorry, there was a problem retrieving match #{match_id}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        match_slice_index(0) unless match_slice_index
        @match_view = MatchView.new match_id, match_slice_index

        Rails.logger.ap action: __method__, hand_ended: @match_view.hand_ended?

        return (
          if @match_view.hand_ended?
            replace_page_contents_with_updated_game_view
          else
            update_match
          end
        )
      end
    )
  end

  def update_match
    return reset_to_match_entry_view(
      "Sorry, there was a problem continuing match #{match_id}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view ||= MatchView.new match_id, match_slice_index

        Rails.logger.ap(
          action: __method__,
          old_match_slice_index: @match_view.slice_index,
          num_slices: @match_view.slices.length
        )

        begin
          @match_view.next_slice!
        rescue => e
          Rails.logger.ap(
            action: __method__,
            suppressed_error: e.message,
            suppression_action: "Re-rendering with most recent slice (##{@match_view.slice_index})"
          )
        end

        Rails.logger.ap(
          action: __method__,
          match_slice_index_to_be_rendered: @match_view.slice_index,
          view_ms: @match_view.state.to_s
        )

        return replace_page_contents_with_updated_game_view
      end
    )
  end

  def play_action
    return reset_to_match_entry_view(
      "Sorry, there was a problem taking action #{params[:poker_action]}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        TableManager.perform_async(
          TableManager::PLAY_ACTION_REQUEST_CODE,
          match_id,
          action: params[:poker_action]
        )
      end
    )
    render nothing: true
  end

  def update_hotkeys
    return reset_to_match_entry_view(
      "Sorry, there was a problem saving hotkeys, #{self.class.report_error_request_message}."
    ) if (
      error? do
        Rails.logger.ap(
          action: __method__,
          params: params
        )

        hotkey_hash = params[PlayerActionsHelper::CUSTOMIZE_HOTKEYS_ID]
        params[PlayerActionsHelper::CUSTOMIZE_HOTKEYS_AMOUNT_KEY].zip(
          params[PlayerActionsHelper::CUSTOMIZE_HOTKEYS_KEYS_HASH_KEY]
        ).each do |amount, key|
          hotkey_hash[Hotkey.wager_hotkey_label(amount.to_f)] = key
        end

        begin
          user.update_hotkeys! hotkey_hash
        rescue User::ConflictingHotkeys => e
          @alert_message = "Sorry, the following hotkeys conflicted and were not saved: \n" << e.message << "\n"

          Rails.logger.ap(
            action: __method__,
            alert_message: @alert_message
          )
        end

        return replace_page_contents_with_updated_game_view
      end
    )
    reset_to_match_entry_view
  end

  def reset_hotkeys
    Rails.logger.ap(action: __method__)

    user.reset_hotkeys!
    return replace_page_contents_with_updated_game_view
  end

  def leave_match
    redirect_to root_path, remote: true
  end

  protected

  def my_helper() PlayerActionsHelper end

  # Replaces the page contents with an updated game view
  def replace_page_contents_with_updated_game_view(
    slice_index=match_slice_index
  )
    @match_view ||= MatchView.new(match_id, slice_index)
    match_slice_index(@match_view.slice_index)
    replace_page_contents(
      replacement_partial: 'player_actions/index',
      html_element: html_element_name_to_class(
        ApplicationHelper::POKER_VIEW_HTML_CLASS
      )
    )
  end
end
