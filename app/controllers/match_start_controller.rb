
# System
require 'socket'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'

# Controller for the 'start a new game' view.
class MatchStartController < ApplicationController
  include ApplicationDefs
  include ApplicationHelper
  include MatchStartHelper

  # Presents the main 'start a new game' view.
  def index
    @match = Match.new
    respond_to do |format|
      format.html {} # Render the default partial
      format.js do
        replace_page_contents NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    while (
      params[:match][:opponent_names].length >
      GAME_DEFINITIONS[
        params[:match][:game_definition_key].to_sym
      ][:num_players] - 1
    )
      params[:match][:opponent_names].pop
    end
    @match = begin
      Match.new(params[:match]).finish_starting!
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view 'Sorry, unable to finish creating a match instance, please try again or rejoin a match already in progress.'
      return
    end

    @request_to_start_match_or_proxy = {
      request: ApplicationDefs::START_MATCH_REQUEST_CODE,
      match_id: @match.id,
      options: [
        '-a', # Append logs with the same name rather than overwrite
        "--t_response #{DEALER_MILLISECOND_TIMEOUT}",
        '--t_hand -1',
        '--t_per_hand -1'
      ].join(' '),
      log_directory: MATCH_LOG_DIRECTORY
    }

    respond_to do |format|
      format.js do
        replace_page_contents wait_for_match_to_start_partial
      end
    end
  end

  def join
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    begin
      opponent_users_match = Match.where(name_from_user: match_name).first
      raise unless opponent_users_match

      # Copy match information
      @match = opponent_users_match.dup
      underscore = '_'
      @match.name_from_user = underscore
      while !@match.save do
        @match.name_from_user << underscore
      end

      # Swap seat
      @match.seat = seat
      @match.opponent_names.insert(
        opponent_users_match.seat - 1,
        HUMAN_OPPONENT_NAME
      )
      @match.opponent_names.delete_at(seat - 1)
      @match.save!(validate: false)

      @request_to_start_match_or_proxy = {
        request: ApplicationDefs::START_PROXY_REQUEST_CODE,
        match_id: @match.id
      }

      respond_to do |format|
        format.js do
          replace_page_contents wait_for_match_to_start_partial
        end
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, unable to join match \"#{match_name}\" in seat #{seat}."
      return
    end
  end

  def rejoin
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    begin
      @match = Match.where(name: match_name, seat: seat).first
      raise unless @match

      respond_to do |format|
        format.js do
          replace_page_contents wait_for_match_to_start_partial
        end
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, unable to find match \"#{match_name}\" in seat #{seat}."
      return
    end
  end
end
