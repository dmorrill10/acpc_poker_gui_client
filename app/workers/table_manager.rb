require 'socket'
require 'thread'

# Load the database configuration
require_relative '../../lib/database_config'

require_relative '../models/match'

# Proxy to connect to the dealer
require_relative 'web_application_player_proxy'
require 'acpc_poker_types'
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

# Email on error
require_relative 'setup_rusen'

require_relative '../../lib/application_defs'

# Easier logging
require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

# To push notifications back to the browser
require 'redis'

# Convenience monkey patching
module ConversionToEnglish
  def to_english
    gsub '_', ' '
  end
end
module StringToEnglishExtension
  refine String do
    include ConversionToEnglish
  end
end
using StringToEnglishExtension
module SymbolToEnglishExtension
  refine Symbol do
    include ConversionToEnglish
  end
end
using SymbolToEnglishExtension
# @todo Move into process_runner
module IntegerAsProcessId
  refine Integer do
    def process_exists?
      begin
        Process.getpgid self
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end
using IntegerAsProcessId

module TableManager
  THIS_MACHINE = Socket.gethostname
  DEALER_HOST = THIS_MACHINE

  CONSTANTS_FILE = File.expand_path('../table_manager.json', __FILE__)
  JSON.parse(File.read(CONSTANTS_FILE)).each do |constant, val|
    TableManager.const_set(constant, val) unless const_defined? constant
  end

  MATCH_LOG_DIRECTORY = File.join(ApplicationDefs::LOG_DIRECTORY, 'match_logs')

  module GracefulErrorHandling
    protected

    # @param [String] match_id The ID of the match in which the exception occurred.
    # @param [Exception] e The exception to log.
    def handle_exception(match_id, e)
      log(
        __method__,
        {
          match_id: match_id,
          message: e.message,
          backtrace: e.backtrace
        },
        Logger::Severity::ERROR
      )
      Match.delete_match! match_id if match_id
    end

    def try
      begin
        yield if block_given?
      rescue => e
        handle_exception match_id, e
        raise e
      end
    end
  end

  module MatchInterface
    include GracefulErrorHandling

    protected

    # @param [String] match_id The ID of the +Match+ instance to retrieve.
    # @return [Match] The desired +Match+ instance.
    # @raise (see Match#find)
    def match_instance(match_id)
      try { match = Match.find match_id }
    end

    # @param [Match] The +Match+ instance to save.
    # @raise (see Match#save)
    def save_match_instance!(match)
      try { match.save }
    end
  end

  module ParamRetrieval
    include GracefulErrorHandling

    protected

    # @param [Hash<String, Object>] params Parameter hash
    # @param parameter_key The key of the parameter to be retrieved.
    # @raise
    def retrieve_parameter_or_raise_exception(params, parameter_key)
      raise StandardError.new("nil params hash given") unless params
      retrieved_param = params[parameter_key]
      unless retrieved_param
        raise StandardError.new("No #{parameter_key.to_english} provided")
      end
      retrieved_param
    end

    # @param [Hash<String, Object>] params Parameter hash
    # @raise (see #param)
    def retrieve_match_id_or_raise_exception(params)
      retrieve_parameter_or_raise_exception params, MATCH_ID_KEY
    end
  end

  class TableQueue
    def initialize(message_server_)
      @syncer = Mutex.new
      @message_server = message_server_
    end


    # @todo
    def enque()
    end

    def dequeue()
    end

    def watch_queue
      # Clean up data from dead matches
      @@table_information.each do |match_id, match_processes|
        unless match_processes[:dealer] && match_processes[:dealer][:pid] && match_processes[:dealer][:pid].process_exists?
          log __method__, msg: "Deleting background processes with match ID #{match_id}"
          @@table_information.delete(match_id)
        end
      end
      # @todo Dequeue

      # @todo Send message to update matches
    end
  end

  class MatchAgentInitializer
    include AcpcPokerTypes
    include SimpleLogging
    include MatchInterface

    def initialize(logger_)
      @logger = logger_
    end

    # @return [Hash<Symbol, Object>] The dealer information
    def start_dealer!(options, match)
      log __method__, options: options

      dealer_arguments = {
        match_name: "\"#{match.name}\"",
        game_def_file_name: match.game_definition_file_name,
        hands: match.number_of_hands,
        random_seed: match.random_seed.to_s,
        player_names: match.player_names.map { |name| "\"#{name}\"" }.join(' '),
        options: (options || {})
      }

      log __method__, {
        match_id: match.id,
        dealer_arguments: dealer_arguments,
        log_directory: MATCH_LOG_DIRECTORY
      }

      match_processes = {}

      # Start the dealer
      dealer_info = AcpcDealer::DealerRunner.start(
        dealer_arguments,
        MATCH_LOG_DIRECTORY
      )

      # Store the port numbers in the database so the web app can access them
      match.port_numbers = dealer_info[:port_numbers]
      save_match_instance! match

      dealer_info
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
      log __method__, {
        match_id: match.id
      }

      game_definition = GameDefinition.parse_file(match.game_definition_file_name)
      match.game_def_hash = game_definition.to_h
      save_match_instance! match

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

        yield players_at_the_table if block_given?
      end

      log "#{__method__}: After starting proxy", {
        match_id: match.id,
        proxy_present: !proxy.nil?
      }

      proxy
    end

    def play!(string_action, match, proxy)
      action = PokerAction.new string_action

      proxy.play!(action) do |players_at_the_table|
        yield players_at_the_table if block_given?
      end
    end
  end

  class TableManagerWorker
    include Sidekiq::Worker
    sidekiq_options retry: false, backtrace: true

    include SimpleLogging # Must be after Sidekiq::Worker to log to the proper file
    include MatchInterface
    include ParamRetrieval

    def initialize
      @@logger ||= Logger.from_file_name(
        File.join(
          ApplicationDefs::LOG_DIRECTORY,
          'table_manager.log'
        )
      ).with_metadata!
      @logger = @@logger
      @agent_initializer = MatchAgentInitializer.new(@logger)

      @@table_information ||= {}
      @@message_server ||= Redis.new(
        host: THIS_MACHINE,
        port: MESSAGE_SERVER_PORT
      )
      @message_server = @@message_server
    end

    def refresh_module(module_constant, module_file, mode_file_base)
      if Object.const_defined?(module_constant)
        Object.send(:remove_const, module_constant)
      end
      $".delete_if {|s| s.include?(mode_file_base) }
      load module_file

      log __method__, msg: "RELOADED #{module_constant}"
    end

    def perform(request, params=nil)
      log __method__, table_information_length: @@table_information.length, request: request, params: params

      case request
      when START_MATCH_REQUEST_CODE
        # @todo Put bots in json so this hacky module reloading doesn't need to be done?
        refresh_module('Bots', File.expand_path('../../../bots/bots.rb', __FILE__), 'bots')
        refresh_module('ApplicationDefs', File.expand_path('../../../lib/application_defs.rb', __FILE__), 'application_defs')
      when DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
        return Match.delete_irrelevant_matches!
      end

      begin
        match_id = retrieve_match_id_or_raise_exception params

        log(
          __method__,
          table_information_length: @@table_information.length,
          request: request,
          match_id: match_id
        )

        ->(&block) { block.call match_instance(match_id) }.call do |match|
          case request
          when START_MATCH_REQUEST_CODE
            raise StandardError.new("Match #{match_id} already started!") if @@table_information[match_id]

            # @todo Enqueue match

            @message_server.publish(
              REALTIME_CHANNEL,
              {
                channel: "#{START_EXHIBITION_MATCH_CHANNEL_PREFIX}#{match.user_name}"
              }.to_json
            )
            @@table_information[match_id] ||= {}
            @@table_information[match_id][:dealer] = @agent_initializer.start_dealer!(
              retrieve_parameter_or_raise_exception(params, OPTIONS_KEY),
              match
            )

            opponents = []
            match.every_bot(DEALER_HOST) do |bot_command|
              opponents << bot_command
            end

            @agent_initializer.start_opponents!(opponents)
            @@table_information[match_id][:proxy] = @agent_initializer.start_proxy!(match) do |players_at_the_table|
              @message_server.publish(
                REALTIME_CHANNEL,
                {
                  channel: "#{PLAYER_ACTION_CHANNEL_PREFIX}#{match.user_name}"
                }.to_json
              )
            end
          when START_PROXY_REQUEST_CODE
            @agent_initializer.start_proxy!(match) do |players_at_the_table|
              @message_server.publish(
                REALTIME_CHANNEL,
                {
                  channel: "#{PLAYER_ACTION_CHANNEL_PREFIX}#{match.user_name}"
                }.to_json
              )
            end
          when PLAY_ACTION_REQUEST_CODE
            unless @@table_information[match.id]
              raise StandardError.new("Request to play in match #{match.id} doesn't exist!")
            end
            proxy = @@table_information[match.id][:proxy]
            unless proxy
              raise StandardError.new("Ignoring request to play in match #{match.id} in seat #{match.seat} when no such proxy exists.")
            end

            action = retrieve_parameter_or_raise_exception(params, ACTION_KEY)
            log __method__, {
              match_id: match.id,
              num_tables: @@table_information.length,
              action: action
            }

            @agent_initializer.play!(action, match, proxy) do |players_at_the_table|
              @message_server.publish(
                REALTIME_CHANNEL,
                {
                  channel: "#{PLAYER_ACTION_CHANNEL_PREFIX}#{match.user_name}"
                }.to_json
              )
            end

            if proxy.match_ended?
              log __method__, msg: "Deleting background processes with match ID #{match.id}"
              @@table_information.delete match.id

              # @todo Dequeue
            end
          else
            raise StandardError.new("Unrecognized request: #{request}")
          end
        end
      rescue => e
        handle_exception match_id, e
        Rusen.notify e # Send an email notification
      end
    end
  end
end
