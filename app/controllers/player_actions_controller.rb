
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
      # @todo This shouldn't be necessary anymore
      @match = Match.find @match_id
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    if @match && @match.slices.length > 0 # Match is being resumed
      # Do nothing
    else # A new match is being started so the user's proxy needs to be started
      player_proxy_arguments = {
        match_id: @match_params[:match_id],
        host_name: 'localhost', port_number: @match.users_port,
        game_definition_file_name: @match_params[:game_definition_file_name],
        player_names: @match.player_names.join(' '),
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
      end
    end
    begin
      replace_page_contents_with_updated_game_view
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem starting the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
    end
  end

  def take_action
    user_poker_action = UserPokerAction.new params[:user_poker_action]
    @match_id ||= user_poker_action.match_id

    Stalker.start_background_job(
      'PlayerProxy.play',
      match_id: user_poker_action.match_id,
      action: user_poker_action.poker_action,
      modifier: user_poker_action.modifier
    )

    update_match_state
  end

  def update_match_state
    @match_id ||= params['match_id']
    begin
      # Delete the last slice since it's no longer needed
      last_slice = Match.find(@match_id).slices.first
      last_slice.delete
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, there was a problem cleaning up the previous match slice before taking action #{params[:user_poker_action]}, please report this incident to #{ADMINISTRATOR_EMAIL}."
      return
    end
    begin
      update_match!
      replace_page_contents_with_updated_game_view
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      # Save the last match state again so that it can
      # be resumed
      begin
        match = Match.find(@match_id)
        match.slices << last_slice if match.slices.empty?
        match.save!
      rescue
        # If the match can't be retrieved or saved then
        # it can't be resumed anyway, so nothing
        # special to do here.
      end
      reset_to_match_entry_view "Sorry, there was a problem continuing the match, please report this incident to #{ADMINISTRATOR_EMAIL}."
    end
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
