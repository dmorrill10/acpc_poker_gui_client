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

require_relative '../../lib/application_defs'

# Easier logging
require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting


class TableManager
  include WorkerHelpers
  include AcpcPokerTypes
  include Sidekiq::Worker
  include SimpleLogging # Must be after Sidekiq::Worker to log to the proper file

  sidekiq_options retry: false, backtrace: true

  DEALER_HOST = Socket.gethostname

  @@table_information ||= {}

  # @todo Poorly named arguments
  def refresh_module(mod, mod_file, mode_file_base)
    if Object.const_defined?(mod)
      Object.send(:remove_const, mod)
    end
    $".delete_if {|s| s.include?(mode_file_base) }
    load mod_file

    log __method__, msg: "RELOADED #{mod}"
  end

  def initialize
    @logger = Logger.from_file_name(
      File.join(
        ApplicationDefs::LOG_DIRECTORY,
        'table_manager.log'
      )
    ).with_metadata!
  end

  def perform(request, match_id, params=nil)
    if request == ApplicationDefs::START_MATCH_REQUEST_CODE
      refresh_module('Bots', File.expand_path('../../../bots/bots.rb', __FILE__), 'bots')
      refresh_module('ApplicationDefs', File.expand_path('../../../lib/application_defs.rb', __FILE__), 'application_defs')
    end
    
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
          log __method__, message: "Unrecognized request", request: params[ApplicationDefs::REQUEST_KEY]
        end
      end
    rescue => e
      handle_exception match_id, e
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
      match_name: "\"#{match.name}\"",
      game_def_file_name: match.game_definition_file_name,
      hands: match.number_of_hands,
      random_seed: match.random_seed.to_s,
      player_names: match.player_names.map { |name| "\"#{name}\"" }.join(' '),
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
    dealer_information = AcpcDealer::DealerRunner.start(
      dealer_arguments,
      log_directory
    )
    match_processes[:dealer] = dealer_information
    @@table_information[match.id] = match_processes

    # Get the player port numbers
    port_numbers = dealer_information[:port_numbers]

    # Store the port numbers in the database so the web app can access them
    match.port_numbers = port_numbers
    save_match_instance match

    self
  end

  def start_opponents!(bot_start_commands)
    bot_start_commands.each do |bot_start_command|
      start_opponent! bot_start_command
    end

    self
  end

  def start_opponent!(bot_start_command)
    log(
      __method__,
      {
        bot_start_command_parameters: bot_start_command,
        command_to_be_run: bot_start_command.join(' '),
        pid: ProcessRunner.go(bot_start_command)
      }
    )

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

    game_definition = GameDefinition.parse_file(match.game_definition_file_name)
    match.game_def_hash = game_definition.to_h
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
        at_least_one_state: !players_at_the_table.match_state.nil?
      }
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

    proxy.play!(action)

    if proxy.match_ended?
      log __method__, msg: "Deleting background processes with match ID #{match.id}"
      @@table_information.delete match.id
    end

    self
  end
end
