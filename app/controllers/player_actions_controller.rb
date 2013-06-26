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
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def update_state
    begin
      @match_view ||= MatchView.new params[:match_id]

      return update unless @match_view.slice.hand_ended?
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      return reset_to_match_entry_view("Sorry, there was a problem retrieving match #{params[:match_id]}, please report this incident to #{ADMINISTRATOR_EMAIL}.")
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
      reset_to_match_entry_view "Sorry, there was a problem cleaning up the previous match slice of #{params[:match_id]}, please report this incident to #{ADMINISTRATOR_EMAIL}."
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
      return reset_to_match_entry_view "Sorry, there was a problem continuing the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
    end
    # Execution should never get here but just in case
    render nothing: true
  end

  def update_hotkeys
    begin
      @match_view ||= MatchView.new params[:match_id]
      @match_view.match.hotkeys.each_with_index do |hotkey, i|
        new_key = params[hotkey['action_label']].strip.capitalize
        if new_key && new_key != hotkey['key']
          @match_view.match.hotkeys[i]['key'] = new_key
        end
      end
      new_key = params[min_wager_hotkey['action_label']].strip.capitalize
      if new_key && new_key != min_wager_hotkey['key']
        min_wager_hotkey['key'] = params[min_wager_hotkey['action_label']]
      end
      @match_view.match.wager_hotkeys.each_with_index do |hotkey, i|
        new_key = params[hotkey['pot_fraction'].to_s].strip.capitalize
        if new_key && new_key != hotkey['key']
          @match_view.match.wager_hotkeys[i]['key'] = new_key
        end
      end
      new_key = params[all_in_hotkey['action_label']].strip.capitalize
      if new_key != all_in_hotkey['key']
        all_in_hotkey['key'] = new_key
      end
      @match_view.match.save!
      return replace_page_contents_with_updated_game_view(params[:match_id])
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      return reset_to_match_entry_view("Sorry, there was a problem saving hotkeys, please  match #{params[:match_id]}, please report this incident to #{ADMINISTRATOR_EMAIL}.")
    end
    render nothing: true
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
