
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

    @request_to_start_match = {
      request: 'dealer',
      match_id: @match.id,
      match_name: @match.match_name,
      game_def_file_name: @match.game_definition_file_name,
      number_of_hands: @match.number_of_hands.to_s,
      random_seed: @match.random_seed.to_s,
      player_names: @match.player_names.join(' '),
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
      @match = Match.where(match_name: match_name).first
      raise unless @match

      # Swap seat
      @match.opponent_names.insert(@match.seat - 1, HUMAN_OPPONENT_NAME)
      @match.opponent_names.delete_at(seat - 1)
      @match.seat = seat

      respond_to do |format|
        format.html { render partial: wait_for_match_to_start_partial }
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

    begin
      @match = Match.where(match_name: match_name).first
      raise unless @match

      respond_to do |format|
        format.html { render partial: wait_for_match_to_start_partial }
        format.js do
          replace_page_contents wait_for_match_to_start_partial
        end
      end
    rescue => e
      Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
      reset_to_match_entry_view "Sorry, unable to find match \"#{match_name}\"."
      return
    end
  end
end
