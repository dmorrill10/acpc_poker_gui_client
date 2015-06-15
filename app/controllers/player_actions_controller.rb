# Local modules
require 'application_defs'
require 'application_helper'
require 'acpc_poker_types/seat'
require 'match'
require 'user'
require 'hotkey'

require 'ap'

# Controller for the main game view where the table and actions are presented to the player.
# Implements the actions in the main match view.
class PlayerActionsController < ApplicationController
  include ApplicationHelper
  include PlayerActionsHelper

  before_filter :log_session

  def log_session
    Rails.logger.ap session: session
  end

  def index
    return reset_to_match_entry_view(
      "Sorry, there was a problem starting the match, #{self.class.report_error_request_message}."
    ) if (
      error? do
        session['waiting_for_response'] = false
        Rails.logger.ap waiting_for_response: session['waiting_for_response']

        replace_page_contents_with_updated_game_view params[:match_id]
      end
    )
  end

  def take_action
    return reset_to_match_entry_view(
      "Sorry, there was a problem taking action #{params[:poker_action]}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        # Initialize the match view so that the app is guaranteed to not update before showing the
        # table.
        @match_view = MatchView.new params[:match_id]
        TableManager.perform_async(
          ApplicationDefs::PLAY_ACTION_REQUEST_CODE,
          params[:match_id],
          action: params[:poker_action]
        )
        session['waiting_for_response'] = true

        replace_page_contents_with_updated_game_view(params[:match_id])
      end
    )
  end

  def update_state
    return reset_to_match_entry_view(
      "Sorry, there was a problem retrieving match #{params[:match_id]}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view = MatchView.new params[:match_id]

        Rails.logger.ap hand_ended: @match_view.hand_ended?

        return update unless @match_view.hand_ended?
      end
    )
    Rails.logger.ap action: 'update_state', waiting_for_response: session['waiting_for_response']

    if params[:match_state] == @match_view.state.to_s
      @update_state_periodically = true;
      return replace_page_contents_with_updated_game_view(params[:match_id])
    end
    replace_page_contents_with_updated_game_view(params[:match_id])
  end

  def update
    deleted_slice = nil

    return reset_to_match_entry_view(
      "Sorry, there was a problem cleaning up the previous match slice of #{params[:match_id]}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view = MatchView.new params[:match_id]

        # Abort the update if there's only one slice
        if @match_view.match.slices.length < 2

          if @match_view.hand_ended?
            # To ensure that we can't try to click 'Next Hand' again.
            session['waiting_for_response'] = true
            return replace_page_contents_with_updated_game_view(params[:match_id])
          end

          Rails.logger.ap action: 'update', param_ms: params[:match_state], view_ms: @match_view.state.to_s, equal_ms: params[:match_state] == @match_view.state.to_s

          if params[:match_state] == @match_view.state.to_s
            @update_state_periodically = true;
            return replace_page_contents_with_updated_game_view(params[:match_id])
          end
          return replace_page_contents_with_updated_game_view(params[:match_id])
        end

        # Delete the first slice in the list since it's no longer needed
        deleted_slice = @match_view.match.slices.first
        deleted_slice.delete
      end
    )

    if (
      error? do
        session['waiting_for_response'] = false
        replace_page_contents_with_updated_game_view(params[:match_id])
      end
    )
      begin
        @match_view.match.slices << deleted_slice if @match_view.match.slices.empty?
        @match_view.match.save!
      rescue => e
        # If the match can't be retrieved or saved then
        # it can't be resumed anyway, so nothing
        # special to do here.
        log_error e
      end
      return(
        reset_to_match_entry_view(
          "Sorry, there was a problem continuing the match, #{self.class.report_error_request_message}."
        )
      )
    end
  end

  def update_hotkeys
    return reset_to_match_entry_view(
      "Sorry, there was a problem saving hotkeys, #{self.class.report_error_request_message}."
    ) if (
      error? do
        conflicting_hotkeys = []

        hotkey_hash = params[hotkeys_param_key]
        params[custom_hotkeys_amount_param_key].zip(
          params[custom_hotkeys_keys_param_key]
        ).each do |amount, key|
          hotkey_hash[Hotkey.wager_hotkey_label(amount.to_f)] = key
        end
        hotkey_hash.each do |action_label, new_key|
          if new_key.blank?
            # Delete custom hotkeys that have been left blank
            user.hotkeys.where(action: action_label).delete unless Hotkey::DEFAULT_HOTKEYS.include?(action_label)
            next
          end
          next if action_label.blank?
          new_key = new_key.strip.capitalize
          next if no_change?(action_label, new_key)

          conflicted_hotkey = user.hotkeys.select { |hotkey| hotkey.key == new_key }.first
          if conflicted_hotkey
            conflicted_label = conflicted_hotkey.action
            if conflicted_label
              conflicting_hotkeys << { key: new_key, current_label: conflicted_label, new_label: action_label }
              next
            end
          end

          previous_hotkey = user.hotkeys.where(action: action_label).first
          if previous_hotkey
            previous_hotkey.key = new_key
            previous_hotkey.save!
          else
            user.hotkeys.create! action: action_label, key: new_key
          end
        end
        user.save!

        unless conflicting_hotkeys.empty?
          @alert_message = "Sorry, the following hotkeys conflicted and were not saved: \n" <<
            conflicting_hotkeys.map do |conflict|
              "    - You tried to set '#{conflict[:new_label]}' to '#{conflict[:key]}' when it was already mapped to '#{conflict[:current_label]}'\n"
            end.join
        end
        return replace_page_contents_with_updated_game_view(params[:match_id])
      end
    )
    render nothing: true
  end

  def reset_hotkeys
    user.reset_hotkeys!
    return replace_page_contents_with_updated_game_view(params[:match_id])
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
