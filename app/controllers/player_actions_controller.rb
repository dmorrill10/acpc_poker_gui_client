
# Gems
require 'stalker'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'
require 'user_poker_action'

require 'ap'

# Controller for the main game view where the table and actions are presented to the player.
# Implements the actions in the main match view.
class PlayerActionsController < ApplicationController
  include ApplicationHelper
  include PlayerActionsHelper

  def index
    @match_params = {
      match_id: params[:match_id],
      port_number: params[:port_number],
      match_name: params[:match_name],
      game_definition_file_name: params[:game_definition_file_name],
      number_of_hands: params[:number_of_hands],
      seat: params[:seat],
      random_seed: params[:random_seed],
      opponent_names: params[:opponent_names],
      millisecond_response_timeout: params[:millisecond_response_timeout]
    }

    @match_id = params[:match_id]
    begin
      @match_view ||= MatchView.new @match_id
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    if @match_view.match && !@match_view.match.slices.empty? # Match is being resumed
      # Do nothing
    else # A new match is being started so the user's proxy needs to be started
      player_proxy_arguments = {
        match_id: @match_params[:match_id],
        host_name: 'localhost', port_number: @match_view.match.users_port,
        game_definition_file_name: @match_params[:game_definition_file_name],
        player_names: @match_view.match.player_names.join(' '),
        number_of_hands: @match_params[:number_of_hands],
        millisecond_response_timeout: @match_params[:millisecond_response_timeout],
        users_seat: (@match_params[:seat].to_i - 1)
      }

      Stalker.start_background_job 'PlayerProxy.start', player_proxy_arguments

      # Wait for the player to start and catch errors
      # @todo Important place to try events instead of polling when the chance arises
      begin
        update_match!
      rescue => e
        Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
        reset_to_match_entry_view "Sorry, there was a problem starting your proxy with the dealer, please report this incident to #{ADMINISTRATOR_EMAIL}."
        return
      end
    end
    begin
      replace_page_contents_with_updated_game_view
      return
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def take_action
    puts "   ACTION: #{params[:poker_action].awesome_inspect}"

    @match_id ||= params[:match_id]

    Stalker.start_background_job(
      'PlayerProxy.play',
      match_id: @match_id,
      action: params[:poker_action],
      modifier: params[:modifier]
    )

    update_match_state
  end

  def update_match_state
    @match_id ||= params['match_id']
    begin
      # Delete the last slice since it's no longer needed
      @match_view ||= MatchView.new @match_id
      last_slice = @match_view.match.slices.first
      last_slice.delete
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem cleaning up the previous match slice before taking action #{params[:user_poker_action]}, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    begin
      update_match!
      replace_page_contents_with_updated_game_view
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
        ap "Unable to restore match slice in match #{@match_id}"
      end
      reset_to_match_entry_view "Sorry, there was a problem continuing the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def check_update_match_state
    @match_id ||= params['match_id']
    begin
      @match_view ||= MatchView.new @match_id
      if @match_view.match.slices.length > 1
        ap "Updating match state..."
        update_match_state
        return
      else
        replace_page_contents_with_updated_game_view
        return
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem checking for a new match state, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
