
# System
require 'socket'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'

# Controller for the 'start a new game' view.
class NewGameController < ApplicationController
  include ApplicationDefs
  include ApplicationHelper
  include NewGameHelper

  # Presents the main 'start a new game' view.
  def new
    @match = Match.new
    respond_to do |format|
      format.html {}
      format.js do
        replace_page_contents NEW_MATCH_PARTIAL
      end
    end
  end

  def create
    @match = Match.new params[:match]

    @match.match_name.strip!

    @match.seat = (rand(2) + 1) unless @match.seat
    @match.random_seed = lambda do
      random_float = rand
      random_int = (random_float * 10**random_float.to_s.length).to_i
      random_int
    end.call unless @match.random_seed

    names = [
      'user', 
      GAME_DEFINITIONS[@match.game_definition_key][:bots].find do |name, runner_class|
        runner_class.to_s == @match.bot
      end.first
    ]
    @match.player_names = (if @match.seat.to_i == 2 then names.reverse else names end).join(' ')

    @match.number_of_hands ||= 1
    @match.game_definition_file_name = GAME_DEFINITIONS[@match.game_definition_key][:file]
    @match.millisecond_response_timeout = DEALER_MILLISECOND_TIMEOUT
    unless @match.save
      reset_to_match_entry_view 'Sorry, unable to start the match, please try again or rejoin a match already in progress.'
    else
      options = [
        '--t_response ' + @match.millisecond_response_timeout.to_s,
        '--t_hand ' + @match.millisecond_response_timeout.to_s,
        '--t_per_hand ' + @match.millisecond_response_timeout.to_s
      ].join ' '

      start_background_job(
        'Dealer.start', 
        {
          match_id: @match.id, 
          match_name: @match.match_name,
          game_def_file_name: @match.game_definition_file_name,
          number_of_hands: @match.number_of_hands.to_s,
          random_seed: @match.random_seed.to_s,
          player_names: @match.player_names,
          options: options,
          log_directory: MATCH_LOG_DIRECTORY
        }
      )

      continue_looping_condition = lambda { |match| !match.port_numbers }
      begin
        temp_match = failsafe_while_for_match(@match.id, continue_looping_condition) {}
      rescue
        @match.delete
        reset_to_match_entry_view 'Sorry, unable to start the match, please try again or rejoin a match already in progress.'
        return
      end
      @match = temp_match

      port_numbers = @match.port_numbers

      user_port_index = @match.seat-1
      opponent_port_index = if 0 == user_port_index then 1 else 0 end
      @port_number = port_numbers[user_port_index]
      @opponent_port_number = port_numbers[opponent_port_index]

      # Start an opponent
      bot_class = Object::const_get(@match.bot)

      # ENSURE THAT ALL REQUIRED KEY-VALUE PAIRS ARE INCLUDED IN THIS BOT
      # ARGUMENT HASH.
      bot_argument_hash = {
        port_number: @opponent_port_number,
        millisecond_response_timeout: @match.millisecond_response_timeout,
        server: Socket.gethostname,
        game_def: @match.game_definition_file_name
      }

      bot_start_command = bot_class.run_command bot_argument_hash

      opponent_arguments = {
        match_id: @match.id,
        bot_start_command: bot_start_command.split(' ')
      }

      start_background_job 'Opponent.start', opponent_arguments

      send_parameters_to_connect_to_dealer
    end
  end

  def rejoin
    match_name = params[:match_name].strip

    begin
      @match = Match.where(match_name: match_name).first
      raise unless @match

      @port_number = @match.port_numbers[@match.seat-1]
      send_parameters_to_connect_to_dealer
    rescue
      reset_to_match_entry_view "Sorry, unable to find match \"#{match_name}\"."
    end
  end
end
