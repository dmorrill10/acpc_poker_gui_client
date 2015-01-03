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
    def kill_process() Process.kill('TERM', self) end
  end
end
using IntegerAsProcessId

# @todo Move into acpc_dealer
module AcpcDealer
  def self.dealer_running?(match_process_hash)
    (
      match_process_hash[:dealer] &&
      match_process_hash[:dealer][:pid] &&
      match_process_hash[:dealer][:pid].process_exists?
    )
  end
end


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
      self
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
      self
    end

    def update_match_queue!
      @message_server.publish(
        REALTIME_CHANNEL,
        {
          channel: "#{UPDATE_MATCH_QUEUE_CHANNEL}"
        }.to_json
      )
      self
    end
  end

  class TableQueue
    include SimpleLogging
    include MatchInterface

    attr_reader :running_matches

    QUEUE_CHECK_INTERVAL = 20 # seconds

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

    def ports_in_use
      @running_matches.values.inject([]) do |ports, m|
        if m[:dealer] && m[:dealer][:port_numbers]
          ports += m[:dealer][:port_numbers]
        end
        ports
      end
    end

    def available_special_ports
      if TableManager::SPECIAL_PORTS_TO_DEALER
        TableManager::SPECIAL_PORTS_TO_DEALER - ports_in_use
      else
        []
      end
    end

    def match_ended!(match_id)
      @syncer.synchronize do
        log __method__, msg: "Deleting background processes with match ID #{match_id}"
        @running_matches.delete match_id
      end
      self
    end

    def enque!(match_id, dealer_options)
      log __method__, match_id: match_id, running_matches: @running_matches

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
      @queue_checking_thread = Thread.new { loop do sleep(QUEUE_CHECK_INTERVAL); check_queue! end }
      self
    end

    def check_queue!
      # Clean up data from dead matches
      @running_matches.each do |match_id, match_processes|
        unless AcpcDealer::dealer_running?(match_processes)
          Match.delete_match! match_id
          match_ended!(match_id)
        end
      end
      @syncer.synchronize do
        if @running_matches.length < ExhibitionConstants::MAX_NUM_MATCHES
          dequeue_without_synchronization!
        end
      end
      self
    end

    def delete_from_queue!(match_id)
      @syncer.synchronize do
        @matches_to_start.delete_if { |m| m[:match_id] == match_id }
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
          match = Match.find match_id
        rescue Mongoid::Errors::DocumentNotFound
          return self if @matches_to_start.empty?
        else
          break
        end
      end

      options = match_info[:options]

      log(
        __method__,
        msg: "Starting dealer for match #{match_id}",
        options: options
      )

      @running_matches[match_id] ||= {}

      special_port_requirements = match.bot_special_port_requirements

      # Add user's port
      special_port_requirements.insert(match.seat - 1, false)

      available_ports_ = available_special_ports
      ports_to_be_used = special_port_requirements.map do |r|
        if r then available_ports_.pop else 0 end
      end

      log(
        __method__,
        msg: "Added #{match_id} list of running matches",
        available_special_ports: available_special_ports,
        special_port_requirements: special_port_requirements,
        :'ports_to_be_used_(zero_for_random)' => ports_to_be_used
      )

      @running_matches[match_id][:dealer] = @agent_interface.start_dealer!(
        options,
        match,
        ports_to_be_used
      )

      log(
        __method__,
        msg: "Dealer started for #{match_id} with pid #{@running_matches[match_id][:dealer][:pid]}"
      )

      opponents = []
      match.every_bot(DEALER_HOST) do |bot_command|
        opponents << bot_command
      end

      @agent_interface.start_opponents!(opponents)

      @running_matches[match_id][:proxy] = @agent_interface.start_proxy!(match) do |players_at_the_table|
        @match_communicator.match_updated! match
      end

      @match_communicator.update_match_queue!
      self
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
    def start_dealer!(options, match, port_numbers=nil)
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
        log_directory: MATCH_LOG_DIRECTORY,
        port_numbers: port_numbers
      }

      # Start the dealer
      dealer_info = AcpcDealer::DealerRunner.start(
        dealer_arguments,
        MATCH_LOG_DIRECTORY,
        port_numbers
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
      pid = ProcessRunner.go(bot_start_command)
      log(
        __method__,
        {
          bot_start_command_parameters: bot_start_command,
          command_to_be_run: bot_start_command.join(' '),
          pid: pid
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

    def check_queue_and_alert_views!
      @@table_queue.check_queue!
      @@match_communicator.update_match_queue!
    end

    def delete_irrelevant_matches!
      log(
        __method__,
        {
          num_matches_before_deleteing: Match.all.length
        }
      )
      Match.delete_irrelevant_matches!
      log(
        __method__,
        {
          num_matches_after_deleteing: Match.all.length
        }
      )
    end

    def delete_started_matches_where_the_dealer_has_died_or_not_persisted!
      @@table_queue.running_matches.each do |match_id, match_info|
        unless (AcpcDealer::dealer_running?(match_info) && Match.id_exists?(match_id))
          log(
            __method__,
            {
              match_id_being_killed: match_id
            }
          )

          kill_match!(match_id)
        end
      end
    end

    def delete_started_matches_that_are_not_running!
      Match.each do |match|
        match_id = match.id.to_s

        log(
          __method__,
          {
            match_to_check: { id: match_id, name: match.name, num_slices: match.slices.length },
            running?: @@table_queue.running_matches[match_id],
            dealer_process: (
              if @@table_queue.running_matches[match_id]
                @@table_queue.running_matches[match_id][:dealer][:pid]
              else
                nil
              end
            ),
            dealer_process_exists?: (
              if @@table_queue.running_matches[match_id]
                AcpcDealer::dealer_running? @@table_queue.running_matches[match_id]
              else
                false
              end
            )
          }
        )

        unless (
          match.slices.empty? || (
            @@table_queue.running_matches[match_id] &&
            AcpcDealer::dealer_running?(@@table_queue.running_matches[match_id])
          )
        )
          Match.delete_match! match_id
          kill_match! match_id
        end
      end
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
          refresh_module(
            'ApplicationDefs',
            File.expand_path('../../../lib/application_defs.rb', __FILE__),
            'application_defs'
          )
        when DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
          delete_irrelevant_matches!
          delete_started_matches_that_are_not_running!
          delete_started_matches_where_the_dealer_has_died_or_not_persisted!

          check_queue_and_alert_views!

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

      match_info = @@table_queue.running_matches[match_id]

      if match_info
        log(
          __method__,
          pid: match_info[:dealer][:pid],
          msg: 'Match is running'
        )

        if AcpcDealer::dealer_running? match_info
          log(
            __method__,
            pid: match_info[:dealer][:pid],
            process_exists: true,
            msg: 'Match is running, attempting to kill'
          )

          match_info[:dealer][:pid].kill_process

          sleep 1 # Give the dealer a chance to exit
          if (
            match_info &&
            AcpcDealer::dealer_running?(match_info)
          )
            raise(
              StandardError.new(
                "Dealer process #{match_info[:dealer][:pid]}
                associated with #{match_id} couldn't be killed!"
              )
            )
          end
        end
        @@table_queue.match_ended!(match_id)
      else
        @@table_queue.delete_from_queue! match_id
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

        @@table_queue.enque!(
          match_id,
          retrieve_parameter_or_raise_exception(params, OPTIONS_KEY)
        )
        @@match_communicator.update_match_queue!
      when START_PROXY_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Starting proxy'
        )

        match = match_instance(match_id)
        @@agent_interface.start_proxy!(match) do |players_at_the_table|
          @@match_communicator.match_updated! match
        end
      when PLAY_ACTION_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Taking action'
        )

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
          log __method__, {
            match_id: match_id,
            action: action,
            msg: "Updating match"
          }
          @@match_communicator.match_updated! match
          if players_at_the_table.match_state.first_state_of_first_round?
            log __method__, {
              match_id: match_id,
              action: action,
              msg: "Updating match"
            }
            @@match_communicator.update_match_queue!
          end
        end

        log __method__, {
          match_id: match_id,
          action: action,
          msg: "Finished taking action"
        }

        if proxy.match_ended?
          log __method__, {
            match_id: match_id,
            action: action,
            msg: "Match is ended"
          }
          @@table_queue.match_ended!(match.id)
          check_queue_and_alert_views!
        end
      when KILL_MATCH
        kill_match! match_id
        check_queue_and_alert_views!
      else
        raise StandardError.new("Unrecognized request: #{request}")
      end
    end
  end
end
