
# Gems
require 'stalker'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'
require 'user_poker_action'

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
      player_names: params[:player_names],
      millisecond_response_timeout: params[:millisecond_response_timeout]
    }

    @match_id = @match_params[:match_id]
    @match = Match.find @match_id
    if @match && @match.slices.length > 0 # Match is being resumed
      @match_slice = @match.slices.last
      @match_slice_index = @match.slices.length
    else # A new match is being started so the user's proxy needs to be started
      player_proxy_arguments = {
        match_id: @match_params[:match_id],
        host_name: 'localhost', port_number: @match_params[:port_number],
        game_definition_file_name: @match_params[:game_definition_file_name],
        player_names: @match_params[:player_names],
        number_of_hands: @match_params[:number_of_hands],
        millisecond_response_timeout: @match_params[:millisecond_response_timeout],
        users_seat: (@match_params[:seat].to_i - 1)
      }

      Stalker.start_background_job 'PlayerProxy.start', player_proxy_arguments

      # Wait for the player to start and catch errors
      begin
        update_match!
      rescue
        reset_to_match_entry_view "Sorry, there was a problem starting the match! Please report this incident to #{ADMINISTRATOR_EMAIL}."
      end
    end
    replace_page_contents_with_updated_game_view
  end

  def take_action
    puts "   ACTIION: #{params[:user_poker_action]}"

    user_poker_action = UserPokerAction.new params[:user_poker_action]
    params[:match_id] = user_poker_action.match_id
    params[:match_slice_index] = user_poker_action.match_slice_index

    Stalker.start_background_job('PlayerProxy.play', match_id: user_poker_action.match_id,
                         action: user_poker_action.poker_action, modifier: user_poker_action.modifier)

    update_match_state
  end

  def update_match_state
    begin
      update_match!
    rescue
      reset_to_match_entry_view "Sorry, there was a problem continuing the match! Please report this incident to #{ADMINISTRATOR_EMAIL}."
    else
      # @todo Move into exception handling
      replace_page_contents_with_updated_game_view
    end
  end

  def leave_match
    redirect_to root_path, remote: true
  end
end
