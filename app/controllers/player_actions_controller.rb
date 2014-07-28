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

  def update_state
    return reset_to_match_entry_view(
      "Sorry, there was a problem retrieving match #{match_id}, #{self.class.report_error_request_message}."
    ) if (
      error? do
        @match_view = MatchView.new match_id, match_slice_index

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
        @match_view ||= MatchView.new match_id, match_slice_index

        Rails.logger.ap(
          action: 'force_update',
          old_match_slice_index: @match_view.slice_index,
          num_slices: @match_view.slices.length
        )

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
        Rails.logger.ap(
          action: 'update_hotkeys',
          params: params
        )

        hotkey_hash = params[hotkeys_param_key]
        params[custom_hotkeys_amount_param_key].zip(
          params[custom_hotkeys_keys_param_key]
        ).each do |amount, key|
          hotkey_hash[Hotkey.wager_hotkey_label(amount.to_f)] = key
        end

        begin
          user.update_hotkeys! hotkey_hash
        rescue User::ConflictingHotkeys => e
          @alert_message = "Sorry, the following hotkeys conflicted and were not saved: \n" << e.message << "\n"
        end

        Rails.logger.ap(
          action: 'update_hotkeys',
          alert_message: @alert_message
        )

        return replace_page_contents_with_updated_game_view
      end
    )
    reset_to_match_entry_view
  end

  def reset_hotkeys
    Rails.logger.ap(action: 'reset_hotkeys')

    user.reset_hotkeys!
    return replace_page_contents_with_updated_game_view
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
