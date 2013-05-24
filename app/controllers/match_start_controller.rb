
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

  # Presents the main 'start a new game' view.
  def index
    @match = Match.new
    respond_to do |format|
      format.html {}
      format.js do
        replace_page_contents NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    while (
      params[:match][:opponent_names].length >
      ApplicationDefs::GAME_DEFINITIONS[
        params[:match][:game_definition_key].to_sym
      ][:num_players] - 1
    )
      params[:match][:opponent_names].pop
    end
    @match = begin
      Match.new(params[:match]).finish_starting!
    rescue => e
      ap "MatchStartController#index: "
      p e.message
      ap 'Backtrace:'
      e.backtrace.each do |line|
        ap line
      end
      reset_to_match_entry_view 'Sorry, unable to start the match, please try again or rejoin a match already in progress.'
      return
    end

    options = [
      '--t_response -1',
      '--t_hand -1',
      '--t_per_hand -1'
    ].join ' '

    Stalker.start_background_job(
      'Dealer.start',
      {
        match_id: @match.id,
        match_name: @match.match_name,
        game_def_file_name: @match.game_definition_file_name,
        number_of_hands: @match.number_of_hands.to_s,
        random_seed: @match.random_seed.to_s,
        player_names: @match.player_names.join(' '),
        options: options,
        log_directory: MATCH_LOG_DIRECTORY
      }
    )

    # @todo Easy place to try events instead of polling when the chance arises
    continue_looping_condition = lambda { |match| match.port_numbers.nil? }
    begin
      temp_match_view = MatchView.failsafe_while_for_match(@match.id, continue_looping_condition)
    rescue => e
      ap "MatchStartController#index: "
      p e.message
      ap 'Backtrace:'
      e.backtrace.each do |line|
        ap line
      end
      temp_match_view.match.delete
      reset_to_match_entry_view 'Sorry, unable to start a dealer, please try again or rejoin a match already in progress.'
      return
    end
    @match = temp_match_view.match

    @match.every_bot(Socket.gethostname) do |bot_command|
      opponent_arguments = {
        match_id: @match.id,
        bot_start_command: bot_command
      }
      Stalker.start_background_job 'Opponent.start', opponent_arguments
    end

    send_parameters_to_connect_to_dealer
  end

  def rejoin
    match_name = params[:match_name].strip

    begin
      @match = Match.where(match_name: match_name).first
      raise unless @match

      @port_number = @match.port_numbers[@match.seat-1]
      send_parameters_to_connect_to_dealer
    rescue => e
      ap "MatchStartController#index: "
      p e.message
      ap 'Backtrace:'
      e.backtrace.each do |line|
        ap line
      end
      reset_to_match_entry_view "Sorry, unable to find match \"#{match_name}\"."
    end
  end
end
