
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
    Match.delete_irrelevant_matches!
    unless user.hotkeys
      error?("Unable to set default hotkeys for #{user.name}, #{self.class.report_error_request_message}") do
        user.reset_hotkeys!
      end
    end

    respond_to do |format|
      format.html {} # Render the default partial
      format.js do
        replace_page_contents NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    params[:match][:opponent_names] = truncate_opponent_names_if_necessary(
      params[:match]
    )
    return reset_to_match_entry_view if (
      error?(
        'Sorry, unable to finish creating a match instance, please try again or rejoin a match already in progress.'
      ) do
        @match = Match.new(params[:match].merge(user_name: user_name)).finish_starting!
      end
    )

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

    wait_for_match_to_start
  end

  def join
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view if (
      error?("Sorry, unable to join match \"#{match_name}\" in seat #{seat}.") do
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
      end
    )

    wait_for_match_to_start
  end

  def rejoin
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view if (
      error?("Sorry, unable to find match \"#{match_name}\" in seat #{seat}.") do
        @match = Match.where(name: match_name, seat: seat).first
        raise unless @match
      end
    )

    wait_for_match_to_start
  end
end
