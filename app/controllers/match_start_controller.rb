
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
    unless user_initialized?
      @alert_message = "Unable to set default hotkeys for #{user.name}, #{self.class.report_error_request_message}"
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
    return reset_to_match_entry_view(
      'Sorry, unable to finish creating a match instance, please try again or rejoin a match already in progress.'
    ) if (
      error? do
        @match = Match.new(params[:match].merge(user_name: user_name)).finish_starting!

        match_id(@match.id)
        @request_code = ApplicationDefs::START_MATCH_REQUEST_CODE

        wait_for_match_to_start
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

        # Copy match information
        @match = opponent_users_match.dup
        underscore = '_'
        @match.name_from_user = underscore
        while !@match.save do
          @match.name_from_user << underscore
        end
        @match.user_name = user.name

        # Swap seat
        @match.seat = seat
        @match.opponent_names.insert(
          opponent_users_match.seat - 1,
          opponent_users_match.user_name
        )
        @match.opponent_names.delete_at(seat - 1)
        @match.save!(validate: false)

        match_id(@match.id)
        @request_code = ApplicationDefs::START_PROXY_REQUEST_CODE

        wait_for_match_to_start
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

        wait_for_match_to_start
      end
    )
  end
end
