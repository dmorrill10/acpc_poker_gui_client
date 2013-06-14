# @todo Why are some param keys symbols and some strings?

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
      @match_view = MatchView.new params[:match_id]
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    if @match_view.match && !@match_view.match.slices.empty? # Match is being resumed

      # @todo Doesn't work when a match is being joined!!!

      # Do nothing
    else # A new match is being started so the user's proxy needs to be started
      @request_to_table_manager = {
        request: 'proxy',
        match_id: params[:match_id],
        host_name: 'localhost', port_number: @match_view.match.users_port,
        game_definition_file_name: params[:game_definition_file_name],
        player_names: @match_view.match.player_names.join(' '),
        number_of_hands: params[:number_of_hands],
        users_seat: (params[:seat].to_i - 1)
      }
    end

    respond_to do |format|
      format.html { render partial: wait_for_match_to_start_partial }
      format.js do
        replace_page_contents wait_for_match_to_start_partial
      end
    end
  end

  def take_action
    puts "   ACTION: #{params[:poker_action].awesome_inspect}"

    @request_to_table_manager = {
      request: 'play',
      match_id: params[:match_id],
      action: params[:poker_action],
      modifier: params[:modifier]
    }

    @match_view = MatchView.new params[:match_id]

    begin
      replace_page_contents_with_updated_game_view params[:match_id]
      return
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem continuing the match after taking your action, please report this incident to #{ADMINISTRATOR_EMAIL}."
    end
  end

  def update_match_state
    last_slice = nil
    begin
      @match_view = MatchView.new params[:match_id]

      # @todo Need to change how this is done
      while @match_view.match.slices.length > 1 && !(@match_view.slice.match_ended? || @match_view.slice.hand_ended?) do
        # Delete the last slice since it's no longer needed
        last_slice = @match_view.match.slices.first
        last_slice.delete
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem cleaning up previous match slices, please report this incident to #{ADMINISTRATOR_EMAIL}."
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
        if last_slice && @match_view.match.slices.empty?
          @match_view.match.slices << last_slice
          @match_view.match.save!
        end
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
