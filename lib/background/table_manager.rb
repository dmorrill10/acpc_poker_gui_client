# Websocket server library
require 'em-websocket'

# JSON parsing
require 'json'

# Load the database configuration
require_relative '../database_config'

require_relative '../../app/models/match'

# Proxy to connect to the dealer
require_relative '../web_application_player_proxy'
require 'acpc_poker_types'
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

require_relative 'worker_helpers'

# Email on error
require_relative 'setup_rusen'

# Easier logging
require_relative '../simple_logging'
using SimpleLogging::MessageFormatting

require_relative '../application_defs'

module AcpcPokerGuiClient
class TableManager
  include WorkerHelpers
  include AcpcPokerTypes
  include SimpleLogging

  def self.listen_to_gui(authorized_client_origin)
    new(authorized_client_origin).listen_to_gui
  end

  def initialize(authorized_client_origin)
    @match_id_to_background_processes = {}
    @authorized_client_origin = authorized_client_origin
    @logger = Logger.from_file_name(File.join(ApplicationDefs::LOG_DIRECTORY, 'table_manager.log')).with_metadata!
  end

  def listen_to_gui
    EventMachine::WebSocket.start(:host => "0.0.0.0", :port => ApplicationDefs::WEBSOCKET_PORT) do |ws|
      ws.onopen do |handshake|
        log "#{__method__}: onopen", origin: handshake.origin

        ws.close unless handshake.origin == @authorized_client_origin
      end
      ws.onclose do |handshake|
        log "#{__method__}: onclose", handshake: handshake
      end
      ws.onmessage do |msg|
        log "#{__method__}: onmessage", msg: msg

        params = JSON.parse(msg)

        log "#{__method__}: onmessage", params: params

        case params[ApplicationDefs::REQUEST_KEY]
        when ApplicationDefs::START_MATCH_REQUEST_CODE

          # @todo Use the information from the match to start opponents and the proxy by organizing the data into params first
          start_dealer!(params).start_opponents!(params, @match).start_proxy!(params, @match)
          ws.send ApplicationDefs::START_PROXY_REQUEST_CODE
        when ApplicationDefs::START_PROXY_REQUEST_CODE
          start_proxy! params
          ws.send ApplicationDefs::START_PROXY_REQUEST_CODE
        when ApplicationDefs::PLAY_ACTION_REQUEST_CODE
          play! params
          ws.send ApplicationDefs::PLAY_ACTION_REQUEST_CODE
        else
          raise "Unrecognized request: #{params[ApplicationDefs::REQUEST_KEY]}"
        end
      end
      ws.onerror do |e|
        error = {error: {message: e.message, backtrace: e.backtrace}}
        log "#{__method__}: onerror", error, Logger::Severity::ERROR
        ws.send error.to_json unless e.kind_of?(EM::WebSocket::WebSocketError) # Notify the GUI
        Rusen.notify e # Send an email notification
      end

      yield if block_given?
    end
  end

  def start_dealer!(params, match=nil)
    log __method__, params: params

    # Clean up data from dead matches
    @match_id_to_background_processes.each do |match_id, match_processes|
      unless match_processes[:dealer][:pid].process_exists?
        log __method__, msg: "Deleting background processes with match ID #{match_id}"
        @match_id_to_background_processes.delete(match_id)
      end
    end

    match_id = if match
      match.id
    else
      params.retrieve_match_id_or_raise_exception
    end
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

    log __method__, {
      match_id: match_id,
      dealer_arguments: dealer_arguments,
      log_directory: log_directory,
      num_background_processes: background_processes.length,
      num_match_id_to_background_processes: @match_id_to_background_processes.length
    }

    return self if background_processes[:dealer]

    # Start the dealer
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
      match = match_instance match_id unless match
      match.port_numbers = port_numbers

      save_match_instance match
      @match = match
    rescue => unable_to_retrieve_port_numbers_from_dealer_exception
      handle_exception match_id, "unable to retrieve player port numbers from the dealer: #{unable_to_retrieve_port_numbers_from_dealer_exception.message}"
      raise unable_to_retrieve_port_numbers_from_dealer_exception
    end

    self
  end

  def start_opponents!(params, match = nil)
    params.each do |opp_params|
      start_opponent! opp_params, match
    end

    self
  end

  def start_opponent!(params, match = nil)
    match_id = if match
      match.id
    else
      params.retrieve_match_id_or_raise_exception
    end

    background_processes = @match_id_to_background_processes[match_id] || {}

    log __method__, {
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

    self
  end

  def start_proxy!(params, match = nil)
    match_id = if match
      match.id
    else
      params.retrieve_match_id_or_raise_exception
    end

    background_processes = @match_id_to_background_processes[match_id] || {}

    log __method__, {
      match_id: match_id,
      num_background_processes: background_processes.length,
      num_match_id_to_background_processes: @match_id_to_background_processes.length
    }

    match = match_instance match_id unless match

    return self if background_processes[:player_proxy][match.seat]

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
      match.betting_type = game_definition.betting_type
      match.number_of_hole_cards = game_definition.number_of_hole_cards
      match.min_wagers = game_definition.min_wagers
      match.blinds = game_definition.blinds
      save_match_instance match
      @match = match

      background_processes[:player_proxy][match.seat] = WebApplicationPlayerProxy.new(
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

    self
  end

  def play!(params)
    match_id = params.retrieve_match_id_or_raise_exception

    unless @match_id_to_background_processes[match_id]
      log(__method__, msg: "Ignoring request to play in match #{match_id} that doesn't exist.")
      return self
    end

    proxy = @match_id_to_background_processes[match_id][:player_proxy][match.seat]

    unless proxy
      log(__method__, msg: "Ignoring request to play in match #{match_id} in seat #{match.seat} when no such proxy exists.")
      return self
    end

    action = PokerAction.new(
      params.retrieve_parameter_or_raise_exception('action').to_sym,
      {modifier: params['modifier']}
    )

    log __method__, {
      match_id: match_id,
      num_match_id_to_background_processes: @match_id_to_background_processes.length
    }

    begin
      proxy.play! action
    rescue => e
      handle_exception match_id, "unable to take action #{action.to_acpc}: #{e.message}"
      raise e
    end

    if proxy.match_ended?
      log __method__, msg: "Deleting background processes with match ID #{match_id}"
      @match_id_to_background_processes.delete match_id
    end

    self
  end
end
end