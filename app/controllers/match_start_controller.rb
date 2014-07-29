
# System
require 'socket'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'
require_relative '../workers/table_manager'

# Controller for the 'start a new game' view.
class MatchStartController < ApplicationController
  include ApplicationDefs
  include ApplicationHelper
  include MatchStartHelper

  INITIAL_MATCH_SLICE_INDEX = -1

  # Presents the main 'start a new game' view.
  def index
    begin
      TableManager::TableManagerWorker.perform_async(
        TableManager::DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
      )
    rescue # Quiet any errors
    end

    unless user_initialized?
      @alert_message = "Unable to set default hotkeys for #{user.name}, #{self.class.report_error_request_message}"
    end

    respond_to do |format|
      format.html {} # Render the default partial
      format.js do
        replace_page_contents replacement_partial: ApplicationHelper::NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    params[:match][:opponent_names] = truncate_opponent_names_if_necessary(
      params[:match]
    )
    return reset_to_match_entry_view(
      'Sorry, unable to finish creating a match instance, please try again or rejoin a match already in progress.'
    ) if (
      error? do
        @match = Match.new(params[:match].merge(user_name: user_name)).finish_starting!

        match_id(@match.id)
        match_slice_index(INITIAL_MATCH_SLICE_INDEX)

        wait_for_match_to_start TableManager::START_MATCH_REQUEST_CODE
      end
    )
  end

  def join
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view(
      "Sorry, unable to join match \"#{match_name}\" in seat #{seat}."
    ) if (
      error? do
        opponent_users_match = Match.where(name_from_user: match_name).first
        raise unless opponent_users_match

        @match = opponent_users_match.copy_for_next_human_player user.name, seat

        match_id(@match.id)
        match_slice_index(INITIAL_MATCH_SLICE_INDEX)

        wait_for_match_to_start TableManager::START_PROXY_REQUEST_CODE
      end
    )
  end

  def rejoin
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view(
      "Sorry, unable to find match \"#{match_name}\" in seat #{seat}."
    ) if (
      error? do
        @match = Match.where(name: match_name, seat: seat).first
        raise unless @match

        match_id(@match.id)
        match_slice_index(@match.slices.length - 2)

        wait_for_match_to_start
      end
    )
  end

  def start_dealer_and_players
    return reset_to_match_entry_view(
      'Sorry, unable to start the dealer and players, please try again or join a match already in progress.'
    ) if (
      error? do
        TableManager::TableManagerWorker.perform_async(
          TableManager::START_MATCH_REQUEST_CODE,
          {
            TableManager::MATCH_ID_KEY => match_id,
            TableManager::OPTIONS_KEY => [
              '-a', # Append logs with the same name rather than overwrite
              "--t_response #{MatchStartHelper::DEALER_MILLISECOND_TIMEOUT}",
              '--t_hand -1',
              '--t_per_hand -1'
            ].join(' ')
          }
        )
      end
    )
    render nothing: true
  end

  def start_proxy_only
    return reset_to_match_entry_view(
      'Sorry, unable to start the dealer and players, please try again or join a match already in progress.'
    ) if (
      error? do
        TableManager::TableManagerWorker.perform_async(
          TableManager::START_PROXY_REQUEST_CODE,
          TableManager::MATCH_ID_KEY => match_id
        )
      end
    )
    render nothing: true
  end

  protected

  def my_helper() MatchStartHelper end

  def wait_for_match_to_start(request_code=@request_code)
    @request_code = request_code
    respond_to do |format|
      format.js do
        replace_page_contents(
          replacement_partial: my_helper::WAIT_FOR_MATCH_TO_START_PARTIAL
        )
      end
    end
  end

  def truncate_opponent_names_if_necessary(match_params)
    while (
      match_params[:opponent_names].length >
      num_players(match_params[:game_definition_key].to_sym) - 1
    )
      match_params[:opponent_names].pop
    end
    match_params[:opponent_names]
  end

  def num_players(game_def_key)
    ApplicationDefs.game_definitions[game_def_key][:num_players]
  end
end
