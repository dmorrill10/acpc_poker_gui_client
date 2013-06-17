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
      respond_to do |format|
        format.js do
          replace_page_contents_with_updated_game_view params[:match_id]
        end
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def update
    last_slice = nil
    begin
      # Delete the last slice since it's no longer needed
      @match_view ||= MatchView.new params[:match_id]
      last_slice = @match_view.match.slices.first
      last_slice.delete
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem cleaning up the previous match slice before taking action #{params[:user_poker_action]}, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    begin
      replace_page_contents_with_updated_game_view params[:match_id]
      return
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
      reset_to_match_entry_view "Sorry, there was a problem continuing the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
