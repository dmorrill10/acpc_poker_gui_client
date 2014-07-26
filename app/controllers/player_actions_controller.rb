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

  def index
    return reset_to_match_entry_view(
      "Sorry, there was a problem starting the match, #{self.class.report_error_request_message}."
    ) if (
      error? do
        replace_page_contents_with_updated_game_view 0
      end
    )
  end

  def take_action
    return reset_to_match_entry_view(
      "Sorry, there was a problem taking action #{params[:poker_action]}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        TableManager.perform_async(
          ApplicationDefs::PLAY_ACTION_REQUEST_CODE,
          session['match_id'],
          action: params[:poker_action]
        )
      end
    )

    render nothing: true
  end

  def update_state
    return reset_to_match_entry_view(
      "Sorry, there was a problem retrieving match #{match_id}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view = MatchView.new match_id, params[:match_slice_index].to_i

        Rails.logger.ap hand_ended: @match_view.hand_ended?

        return (
          if @match_view.hand_ended?
            replace_page_contents_with_updated_game_view
          else
            force_update
          end
        )
      end
    )
  end

  def force_update
    return reset_to_match_entry_view(
      "Sorry, there was a problem continuing match #{match_id}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view ||= MatchView.new match_id, params[:match_slice_index].to_i
        @match_view.next_slice!

        Rails.logger.ap(
          action: 'force_update',
          match_slice_index_to_be_rendered: @match_view.slice_index,
          view_ms: @match_view.state.to_s
        )

        return replace_page_contents_with_updated_game_view
      end
    )
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
