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
    begin
      replace_page_contents_with_updated_game_view params[:match_id]
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, #{self.class.report_error_request_message}."
      return
    end
  end

  def update_state
    begin
      @match_view ||= MatchView.new params[:match_id]

      return update unless @match_view.slice.hand_ended?
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      return reset_to_match_entry_view("Sorry, there was a problem retrieving match #{params[:match_id]}, #{self.class.report_error_request_message}.")
    end
    render nothing: true
  end

  def update
    last_slice = nil
    begin
      @match_view ||= MatchView.new params[:match_id]

      # Abort if there is only one slice in the match view
      if @match_view.match.slices.length < 2
        return render(nothing: true)
      end

      # Delete the last slice since it's no longer needed
      last_slice = @match_view.match.slices.first
      last_slice.delete
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem cleaning up the previous match slice of #{params[:match_id]}, #{self.class.report_error_request_message}."
      return
    end
    begin
      return replace_page_contents_with_updated_game_view(params[:match_id])
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      # Save the last match state again so that it can
      # be resumed
      begin
        @match_view.match.slices << last_slice if @match_view.match.slices.empty?
        @match_view.match.save!
      rescue
        # If the match can't be retrieved or saved then
        # it can't be resumed anyway, so nothing
        # special to do here.
        ap "Unable to restore match slice in match #{params[:match_id]}"
      end
      return reset_to_match_entry_view "Sorry, there was a problem continuing the match, #{self.class.report_error_request_message}."
    end
    # Execution should never get here but just in case
    render nothing: true
  end

  def update_hotkeys
    begin
      @match_view ||= MatchView.new params[:match_id]

      Rails.logger.ap params[hotkeys_param_key]

      conflicting_hotkeys = []
      params[hotkeys_param_key].each do |action_label, new_key|
        next if action_label.blank? || new_key.blank?
        new_key = new_key.strip.capitalize
        next if no_change?(action_label, new_key)

        # @todo Move into User model

        conflicted_label = match.hotkeys.select { |label, parameters| parameters['key'] == new_key }.keys.first
        if conflicted_label
          conflicting_hotkeys << { key: new_key, current_label: conflicted_label, new_label: action_label }
          next
        end

        match.hotkeys[action_label]['key'] = new_key
      end
      match.save!

      unless conflicting_hotkeys.empty?
        @alert_message = "Sorry, the following hotkeys conflicted and were not saved: \n" <<
          conflicting_hotkeys.map do |conflict|
            "    - You tried to set '#{conflict[:new_label]}' to '#{conflict[:key]}' when it was already mapped to '#{conflict[:current_label]}'\n"
          end.join
      end
      return replace_page_contents_with_updated_game_view(params[:match_id])
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      return reset_to_match_entry_view(
        "Sorry, there was a problem saving hotkeys, #{self.class.report_error_request_message}."
      )
    end
    render nothing: true
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
