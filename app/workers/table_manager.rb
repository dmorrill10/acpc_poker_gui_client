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

# For job scheduling
require 'sidekiq'

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
  module ExhibitionConstants
    JSON.parse(File.read(File.expand_path('../../constants/exhibition.json', __FILE__))).each do |constant, val|
      ExhibitionConstants.const_set(constant, val) unless const_defined? constant
    end
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

    def try(match_id)
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
      try(match_id) { match = Match.find match_id }
    end

    # @param [Match] The +Match+ instance to save.
    # @raise (see Match#save)
    def save_match_instance!(match)
      try(match.id) { match.save }
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

  class MatchCommunicator
    def initialize
      @message_server = Redis.new(
        host: THIS_MACHINE,
        port: MESSAGE_SERVER_PORT
      )
    end

    def match_updated!(match)
      @message_server.publish(
        REALTIME_CHANNEL,
        {
          channel: "#{PLAYER_ACTION_CHANNEL_PREFIX}#{match.id.to_s}"
        }.to_json
      )
    end
  end

  class TableQueue
    include SimpleLogging
    include MatchInterface

    attr_reader :running_matches

    def initialize(match_communicator_, agent_interface_, logger_)
      @syncer = Mutex.new
      @match_communicator = match_communicator_
      @agent_interface = agent_interface_
      @logger = logger_
      @matches_to_start = []
      @running_matches = {}
    end

    def length
      @matches_to_start.length
    end

    def match_ended!(match_id)
      @syncer.synchronize do
        log __method__, msg: "Deleting background processes with match ID #{match_id}"
        running_matches.delete match.id
        dequeue_without_synchronization!
      end
    end

    def enque!(match_id, dealer_options)
      raise StandardError.new("Match #{match_id} already started!") if @running_matches[match_id]

      @syncer.synchronize do
        @matches_to_start << {match_id: match_id, options: dealer_options}

        if @running_matches.length < ExhibitionConstants::MAX_NUM_MATCHES
          dequeue_without_synchronization!
        end
      end

      self
    end

    def dequeue!
      @syncer.synchronize { dequeue_without_synchronization! }
      self
    end

    def watch_queue!
      @queue_checking_thread = Thread.new { while(1) do sleep(20); check_queue! end }
      self
    end

    def check_queue!
      # Clean up data from dead matches
      @running_matches.each do |match_id, match_processes|
        unless match_processes[:dealer] && match_processes[:dealer][:pid] && match_processes[:dealer][:pid].process_exists?
          Match.delete_match! match_id
          @running_matches.match_ended!(match_id)
        end
      end
      self
    end

    protected

    def dequeue_without_synchronization!
      return self if @matches_to_start.empty?

      match_info = nil
      match_id = nil
      match = nil
      loop do
        match_info = @matches_to_start.shift
        match_id = match_info[:match_id]
        begin
          match = match_instance(match_id)
        rescue Mongoid::Errors::DocumentNotFound
          return self if @matches_to_start.empty?
        else
          break
        end
      end

      options = match_info[:options]

      @running_matches[match_id] ||= {}
      @running_matches[match_id][:dealer] = @agent_interface.start_dealer!(
        options,
        match
      )

      opponents = []
      match.every_bot(DEALER_HOST) do |bot_command|
        opponents << bot_command
      end

      @agent_interface.start_opponents!(opponents)
      @running_matches[match_id][:proxy] = @agent_interface.start_proxy!(match) do |players_at_the_table|
        @match_communicator.match_updated! match
      end
    end
  end

  class MatchAgentInterface
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

      @@agent_interface ||= MatchAgentInterface.new(@logger)
      @@match_communicator ||= MatchCommunicator.new

      @@table_queue ||= nil
      unless @@table_queue
        @@table_queue = TableQueue.new(@@match_communicator, @@agent_interface, @logger)
        @@table_queue.watch_queue!
      end
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
      begin
        log(
          __method__,
          table_queue_length: @@table_queue.length,
          table_queue_running_matches_length: @@table_queue.running_matches.length,
          request: request,
          params: params
        )

        case request
        when START_MATCH_REQUEST_CODE
          # @todo Put bots in json so this hacky module reloading doesn't need to be done?
          refresh_module('Bots', File.expand_path('../../../bots/bots.rb', __FILE__), 'bots')
          refresh_module('ApplicationDefs', File.expand_path('../../../lib/application_defs.rb', __FILE__), 'application_defs')
        when DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
          log __method__, num_matches_before_deleting: Match.all.length
          Match.delete_irrelevant_matches!
          log __method__, num_matches_after_deleting: Match.all.length
          return
        end

        match_id = retrieve_match_id_or_raise_exception params

        log(
          __method__,
          table_queue_length: @@table_queue.length,
          table_queue_running_matches_length: @@table_queue.running_matches.length,
          request: request,
          match_id: match_id
        )

        do_request!(request, match_id, params)
      rescue => e
        handle_exception match_id, e
        Rusen.notify e # Send an email notification
      end
    end

    def kill_match!(match_id)
      log(
        __method__,
        match_id: match_id
      )

      if @@table_queue.running_matches[match_id]
        log(
          __method__,
          pid: @@table_queue.running_matches[match_id][:dealer][:pid],
          msg: 'Match is running'
        )

        if @@table_queue.running_matches[match_id][:dealer][:pid].process_exists?
          log(
            __method__,
            pid: @@table_queue.running_matches[match_id][:dealer][:pid],
            process_exists: true,
            msg: 'Match is running, attempting to kill'
          )

          Process.kill(
            'TERM',
            @@table_queue.running_matches[match_id][:dealer][:pid]
          )
          if @@table_queue.running_matches[match_id][:dealer][:pid].process_exists?
            raise StandardError.new("Dealer process #{@@table_queue.running_matches[match_id][:dealer][:pid]} associated with #{match_id} couldn't be killed!")
          end
        end
        @@table_queue.match_ended!(match_id)
      end
    end

    protected

    def do_request!(request, match_id, params)
      case request
      when START_MATCH_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Enqueuing match'
        )

        @@table_queue.enque! match_id, retrieve_parameter_or_raise_exception(params, OPTIONS_KEY)
      when START_PROXY_REQUEST_CODE
        match = match_instance(match_id)
        @@agent_interface.start_proxy!(match) do |players_at_the_table|
          @@match_communicator.match_updated! match
        end
      when PLAY_ACTION_REQUEST_CODE
        unless @@table_queue.running_matches[match_id]
          raise StandardError.new("Request to play in match #{match_id} when it doesn't exist!")
        end
        match = match_instance(match_id)
        proxy = @@table_queue.running_matches[match_id][:proxy]
        unless proxy
          raise StandardError.new("Ignoring request to play in match #{match_id} in seat #{match.seat} when no such proxy exists.")
        end

        action = retrieve_parameter_or_raise_exception(params, ACTION_KEY)
        log __method__, {
          match_id: match_id,
          num_tables: @@table_queue.running_matches.length,
          action: action
        }

        @@agent_interface.play!(action, match, proxy) do |players_at_the_table|
          @@match_communicator.match_updated! match
        end

        @@table_queue.match_ended!(match.id) if proxy.match_ended?
      when KILL_MATCH
        kill_match! match_id
      else
        raise StandardError.new("Unrecognized request: #{request}")
      end
    end
  end
end
