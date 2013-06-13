#!/usr/bin/env ruby

# Join standard out and standard error
STDERR.sync = STDOUT.sync = true

# Websocket server library
require 'em-websocket'

# JSON parsing
require 'json'

# Load the database configuration without the Rails environment
require_relative '../database_config'

# To store match data
require_relative '../../app/models/match'

# To encapsulate dealer information
require 'acpc_poker_basic_proxy'

# To encapsulate poker actions
require 'acpc_poker_types'

# For game logic
require_relative '../web_application_player_proxy'

# To run the dealer
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

# Helpers
require_relative 'worker_helpers'

# Email on error
require_relative 'setup_rusen'


module AcpcPokerGuiClient
  class TableManager
    include WorkerHelpers
    include AcpcPokerTypes

    def initialize
      @match_id_to_background_processes = {}
    end

    def listen_to_gui
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen do |handshake|
          # @todo Log
          puts "WebSocket connection open"
        end
        ws.onclose do
          # @todo Log
          puts "Connection closed"
        end
        ws.onmessage do |msg|
          puts "msg: #{msg}"

          # @todo Log
          params = JSON.parse(msg)

          puts "params: #{params}"

          case params['request']
          when 'dealer'
            start_dealer params
            ws.send 'dealer'
          when 'opponents'
            start_opponents params['opponents']
            ws.send 'opponents'
          when 'proxy'
            start_proxy params
            ws.send 'proxy'
          when 'play'
            play params
            ws.send 'play'
          else
            raise "Unrecognized request: #{params['request']}"
          end
        end
        ws.onerror do |e|
          # @todo Log and notify GUI
          puts "Error: #{e}"
          Rusen.notify e # Send an email notification
        end

        yield if block_given?
      end
    end

    def start_dealer(params)
      puts "start_dealer: #{params}"

      # Clean up data from dead matches
      @match_id_to_background_processes.each do |match_id, match_processes|
        unless match_processes[:dealer][:pid].process_exists?
          log "#{__method__}: Deleting background processes with match ID #{match_id}"
          @match_id_to_background_processes.delete(match_id)
        end
      end

      match_id = params.retrieve_match_id_or_raise_exception
      dealer_arguments = {
        match_name: params.retrieve_parameter_or_raise_exception('match_name'),
        game_def_file_name: params.retrieve_parameter_or_raise_exception('game_def_file_name'),
        hands: params.retrieve_parameter_or_raise_exception('number_of_hands'),
        random_seed: params.retrieve_parameter_or_raise_exception('random_seed'),
        player_names: params.retrieve_parameter_or_raise_exception('player_names'),
        options: (params['options'] || {})
      }
      log_directory = params['log_directory']

      background_processes = @match_id_to_background_processes[match_id] || {}

      log "#{__method__}: ", {
        match_id: match_id,
        dealer_arguments: dealer_arguments,
        log_directory: log_directory,
        num_background_processes: background_processes.length,
        num_match_id_to_background_processes: @match_id_to_background_processes.length
      }

      # Start the dealer

      puts "background_processes: #{background_processes}"

      unless background_processes[:dealer]
        begin
          background_processes[:dealer] = AcpcDealer::DealerRunner.start(
            dealer_arguments,
            log_directory
          )
          @match_id_to_background_processes[match_id] = background_processes
        rescue => unable_to_start_dealer_exception
          handle_exception match_id, "unable to start dealer: #{unable_to_start_dealer_exception.message}"
          raise unable_to_start_dealer_exception
        end

        # Get the player port numbers
        begin
          port_numbers = @match_id_to_background_processes[match_id][:dealer][:port_numbers]

          # Store the port numbers in the database so the web app. can access them
          match = match_instance match_id
          match.port_numbers = port_numbers

          puts "Saving port numbers: #{match.port_numbers}"

          save_match_instance match
        rescue => unable_to_retrieve_port_numbers_from_dealer_exception
          handle_exception match_id, "unable to retrieve player port numbers from the dealer: #{unable_to_retrieve_port_numbers_from_dealer_exception.message}"
          raise unable_to_retrieve_port_numbers_from_dealer_exception
        end
      end
    end

    def start_opponents(params)
      params.each do |opp_params|
        start_opponent opp_params
      end
    end

    def start_opponent(params)
      match_id = params.retrieve_match_id_or_raise_exception

      background_processes = @match_id_to_background_processes[match_id] || {}

      log "Stalker.job('Opponent.start'): ", {
        match_id: match_id,
        num_background_processes: background_processes.length,
        num_match_id_to_background_processes: @match_id_to_background_processes.length
      }

      bot_start_command = params.retrieve_parameter_or_raise_exception 'bot_start_command'

      begin
        ProcessRunner.go bot_start_command
      rescue => unable_to_start_bot_exception
        handle_exception match_id, "unable to start bot with command \"#{bot_start_command}\": #{unable_to_start_bot_exception.message}"
        raise unable_to_start_bot_exception
      end
    end

    def start_proxy(params)
      match_id = params.retrieve_match_id_or_raise_exception

      background_processes = @match_id_to_background_processes[match_id] || {}

      log "Stalker.job('PlayerProxy.start'): ", {
        match_id: match_id,
        num_background_processes: background_processes.length,
        num_match_id_to_background_processes: @match_id_to_background_processes.length
      }

      unless background_processes[:player_proxy]
        host_name = params.retrieve_parameter_or_raise_exception 'host_name'
        port_number = params.retrieve_parameter_or_raise_exception 'port_number'
        player_names = params.retrieve_parameter_or_raise_exception 'player_names'
        number_of_hands = params.retrieve_parameter_or_raise_exception('number_of_hands').to_i
        game_definition_file_name = params.retrieve_parameter_or_raise_exception 'game_definition_file_name'
        users_seat = params.retrieve_parameter_or_raise_exception('users_seat').to_i

        dealer_information = AcpcDealer::ConnectionInformation.new port_number, host_name

        begin
          game_definition = GameDefinition.parse_file(game_definition_file_name)
          # Store some necessary game definition properties in the database so the web app can access
          # them without parsing the game definition itself
          match = match_instance match_id
          match.betting_type = game_definition.betting_type
          match.number_of_hole_cards = game_definition.number_of_hole_cards
          match.min_wagers = game_definition.min_wagers
          match.blinds = game_definition.blinds
          save_match_instance match

          background_processes[:player_proxy] = WebApplicationPlayerProxy.new(
            match_id,
            dealer_information,
            users_seat,
            game_definition,
            player_names,
            number_of_hands
          )
        rescue => e
          handle_exception match_id, "unable to start the user's proxy: #{e.message}"
          raise e
        end

        @match_id_to_background_processes[match_id] = background_processes
      end
    end

    def play(params)
      match_id = params.retrieve_match_id_or_raise_exception

      unless @match_id_to_background_processes[match_id]
        puts "Ignoring request to play in match #{match_id} that doesn't exist."
        return
      end

      action = PokerAction.new(
        params.retrieve_parameter_or_raise_exception('action').to_sym,
        {modifier: params['modifier']}
      )

      log "Stalker.job('PlayerProxy.play'): ", {
        match_id: match_id,
        num_match_id_to_background_processes: @match_id_to_background_processes.length
      }

      begin
        @match_id_to_background_processes[match_id][:player_proxy].play! action
      rescue => e
        handle_exception match_id, "unable to take action #{action.to_acpc}: #{e.message}"
        raise e
      end

      if @match_id_to_background_processes[match_id][:player_proxy].match_ended?
        log "Stalker.job('PlayerProxy.play'): Deleting background processes with match ID #{match_id}"
        @match_id_to_background_processes.delete match_id
      end
    end
  end
end

AcpcPokerGuiClient::TableManager.new.listen_to_gui