require 'socket'

# Load the database configuration
require_relative '../../lib/database_config'

require_relative '../models/match'

# Proxy to connect to the dealer
require_relative '../../lib/web_application_player_proxy'
require 'acpc_poker_types'
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

require_relative '../../lib/background/worker_helpers'

# Email on error
require_relative '../../lib/background/setup_rusen'

# Easier logging
require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

require_relative '../../lib/application_defs'

class TableManager
  include WorkerHelpers
  include AcpcPokerTypes
  include SimpleLogging
  include Sidekiq::Worker

  sidekiq_options retry: false, backtrace: true

  DEALER_HOST = Socket.gethostname

  @@table_information ||= {}
  @@logger ||= Logger.from_file_name(File.join(ApplicationDefs::LOG_DIRECTORY, 'table_manager.log')).with_metadata!

  def perform(request, match_id, params=nil)
    log __method__, table_information_length: @@table_information.length, request: request, match_id: match_id, params: params

    begin
      ->(&block) { block.call match_instance(match_id) }.call do |match|
        case request
        when ApplicationDefs::START_MATCH_REQUEST_CODE
          start_dealer!(params, match)

          opponents = []
          match.every_bot(DEALER_HOST) do |bot_command|
            opponents << bot_command
          end

          start_opponents!(opponents).start_proxy!(match)
        when ApplicationDefs::START_PROXY_REQUEST_CODE
          start_proxy! match
        when ApplicationDefs::PLAY_ACTION_REQUEST_CODE
          play! params, match
        else
          raise "Unrecognized request: #{params[ApplicationDefs::REQUEST_KEY]}"
        end
      end
    rescue => e
      error = {error: {message: e.message, backtrace: e.backtrace}}
      log "#{__method__}: rescued", error, Logger::Severity::ERROR
      Rusen.notify e # Send an email notification
    end
  end

  def start_dealer!(params, match)
    log __method__, params: params

    # Clean up data from dead matches
    @@table_information.each do |match_id, match_processes|
      unless match_processes[:dealer] && match_processes[:dealer][:pid] && match_processes[:dealer][:pid].process_exists?
        log __method__, msg: "Deleting background processes with match ID #{match_id}"
        @@table_information.delete(match_id)
      end
    end

    dealer_arguments = {
      match_name: match.name,
      game_def_file_name: match.game_definition_file_name,
      hands: match.number_of_hands,
      random_seed: match.random_seed.to_s,
      player_names: match.player_names.join(' '),
      options: (params['options'] || {})
    }
    log_directory = params['log_directory']

    match_processes = @@table_information[match.id] || {}

    log __method__, {
      match_id: match.id,
      dealer_arguments: dealer_arguments,
      log_directory: log_directory,
      num_tables: @@table_information.length
    }

    dealer_information = match_processes[:dealer] || {}

    return self if dealer_information[:pid] && dealer_information[:pid].process_exists? # The dealer is already started

    # Start the dealer
    begin
      dealer_information = AcpcDealer::DealerRunner.start(
        dealer_arguments,
        log_directory
      )
      match_processes[:dealer] = dealer_information
      @@table_information[match.id] = match_processes
    rescue => unable_to_start_dealer_exception
      full_msg = unable_to_start_dealer_exception.message << "\n#{unable_to_start_dealer_exception.backtrace}"
      handle_exception match.id, "unable to start dealer: #{full_msg}"
      raise unable_to_start_dealer_exception
    end

    # Get the player port numbers
    begin
      port_numbers = dealer_information[:port_numbers]

      # Store the port numbers in the database so the web app can access them
      match.port_numbers = port_numbers

      save_match_instance match
    rescue => unable_to_retrieve_port_numbers_from_dealer_exception
      full_msg = unable_to_retrieve_port_numbers_from_dealer_exception.message << "\n#{unable_to_retrieve_port_numbers_from_dealer_exception.backtrace}"
      handle_exception match.id, "unable to retrieve player port numbers from the dealer: #{full_msg}"
      raise unable_to_retrieve_port_numbers_from_dealer_exception
    end

    self
  end

  def start_opponents!(bot_start_commands)
    bot_start_commands.each do |bot_start_command|
      start_opponent! bot_start_command
    end

    self
  end

  def start_opponent!(bot_start_command)
    log __method__, bot_start_command: bot_start_command

    begin
      log __method__, pid: ProcessRunner.go(bot_start_command)
    rescue => unable_to_start_bot_exception
      full_msg = unable_to_start_bot_exception.message << "\n#{unable_to_start_bot_exception.backtrace}"
      handle_exception match_id, "unable to start bot with command \"#{bot_start_command}\": #{full_msg}"
      raise unable_to_start_bot_exception
    end

    self
  end

  def start_proxy!(match)
    match_processes = @@table_information[match.id] || {}
    proxy = match_processes[:proxy]

    log __method__, {
      match_id: match.id,
      num_tables: @@table_information.length,
      num_match_processes: match_processes.length,
      proxy_present: !proxy.nil?
    }

    return self if proxy

    begin
      game_definition = GameDefinition.parse_file(match.game_definition_file_name)
      # Store some necessary game definition properties in the database so the web app can access
      # them without parsing the game definition itself
      match.betting_type = game_definition.betting_type
      match.number_of_hole_cards = game_definition.number_of_hole_cards
      match.min_wagers = game_definition.min_wagers
      match.blinds = game_definition.blinds
      save_match_instance match

      proxy = WebApplicationPlayerProxy.new(
        match.id,
        AcpcDealer::ConnectionInformation.new(
          match.port_numbers[match.seat - 1],
          DEALER_HOST
        ),
        match.seat - 1,
        game_definition,
        match.player_names.join(' '),
        match.number_of_hands
      ) do |players_at_the_table|
        log "#{__method__}: Initializing proxy", {
          match_id: match.id,
          at_least_one_state: !players_at_the_table.transition.next_state.nil?
        }
      end
    rescue => e
      full_msg = e.message << "\n#{e.backtrace}"
      handle_exception match.id, "unable to start the user's proxy: #{full_msg}"
      raise e
    end

    log "#{__method__}: After starting proxy", {
      match_id: match.id,
      proxy_present: !proxy.nil?
    }

    match_processes[:proxy] = proxy
    @@table_information[match.id] = match_processes

    self
  end

  def play!(params, match)
    unless @@table_information[match.id]
      log(__method__, msg: "Ignoring request to play in match #{match.id} that doesn't exist.")
      return self
    end

    proxy = @@table_information[match.id][:proxy]

    unless proxy
      log(__method__, msg: "Ignoring request to play in match #{match.id} in seat #{match.seat} when no such proxy exists.")
      return self
    end

    action = PokerAction.new(
      params.retrieve_parameter_or_raise_exception('action')
    )

    log __method__, {
      match_id: match.id,
      num_tables: @@table_information.length
    }

    begin
      proxy.play!(action) {}
    rescue => e
      full_msg = e.message << "\n#{e.backtrace}"
      handle_exception match.id, "unable to take action #{action.to_acpc}: #{full_msg}"
      raise e
    end

    if proxy.match_ended?
      log __method__, msg: "Deleting background processes with match ID #{match.id}"
      @@table_information.delete match.id
    end

    self
  end
end