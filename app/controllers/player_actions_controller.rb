# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'

require 'ap'

require 'acpc_poker_types/seat'

# Controller for the main game view where the table and actions are presented to the player.
# Implements the actions in the main match view.
class PlayerActionsController < ApplicationController
  include ApplicationHelper
  include PlayerActionsHelper

  def index
    return reset_to_match_entry_view if (
      error?(
        "Sorry, there was a problem starting the match, #{self.class.report_error_request_message}."
      ) { replace_page_contents_with_updated_game_view params[:match_id] }
    )
  end

  def take_action
    return reset_to_match_entry_view if (
      error?(
        "Sorry, there was a problem taking action #{params[:poker_action]}, #{self.class.report_error_request_message}."
      ) do
        TableManager.perform_async(
          ApplicationDefs::PLAY_ACTION_REQUEST_CODE,
          params[:match_id],
          action: params[:poker_action]
        )
        session[:waiting_for_response] = true
        replace_page_contents_with_updated_game_view(params[:match_id])
      end
    )
  end

  def update_state
    return reset_to_match_entry_view if (
      error?(
        "Sorry, there was a problem retrieving match #{params[:match_id]}, #{self.class.report_error_request_message}."
      ) do
        @match_view ||= MatchView.new params[:match_id]
        return update unless @match_view.slice.hand_ended?
      end
    )
    render nothing: true
  end

  def update
    last_slice = nil

    return reset_to_match_entry_view if (
      error?(
        "Sorry, there was a problem cleaning up the previous match slice of #{params[:match_id]}, #{self.class.report_error_request_message}."
      ) do
        @match_view ||= MatchView.new params[:match_id]

        # Abort if there is only one slice in the match view
        if @match_view.match.slices.length < 2
          return render(nothing: true)
        end

        # Delete the last slice since it's no longer needed
        last_slice = @match_view.match.slices.first
        last_slice.delete
      end
    )

    if (
      error?(
        "Sorry, there was a problem continuing the match, #{self.class.report_error_request_message}."
      ) do
        session[:waiting_for_response] = false
        replace_page_contents_with_updated_game_view(params[:match_id])
      end
    )
      begin
        @match_view.match.slices << last_slice if @match_view.match.slices.empty?
        @match_view.match.save!
      rescue => e
        # If the match can't be retrieved or saved then
        # it can't be resumed anyway, so nothing
        # special to do here.
        log_error e
      end
      return reset_to_match_entry_view
    end
  end

  def update_hotkeys
    return reset_to_match_entry_view if (
      error?(
        "Sorry, there was a problem saving hotkeys, #{self.class.report_error_request_message}."
      ) do
        conflicting_hotkeys = []
        params[hotkeys_param_key].each do |action_label, new_key|
          next if action_label.blank? || new_key.blank?
          new_key = new_key.strip.capitalize
          next if no_change?(action_label, new_key)

          conflicted_label = user.hotkeys.select { |label, key| key == new_key }.keys.first
          if conflicted_label
            conflicting_hotkeys << { key: new_key, current_label: conflicted_label, new_label: action_label }
            next
          end

          user.hotkeys[action_label] = new_key
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
    Rails.logger.ap "Resetting!"
    user.reset_hotkeys!
    return replace_page_contents_with_updated_game_view(params[:match_id])
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
