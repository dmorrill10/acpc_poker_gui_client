require 'thread'
require_relative 'table_manager/table_manager'
using TableManager::MonkeyPatches::IntegerAsProcessId

# Email on error
require_relative 'setup_rusen'

# For job scheduling
require 'sidekiq'

require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

require 'timeout'

module TableManager
  class Null
    def method_missing(*args, &block)
      self
    end
  end
  module HandleException
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
    end
  end

  class Maintainer
    include SimpleLogging
    include ParamRetrieval
    include HandleException

    MAINTENANCE_INTERVAL = 30 # seconds

    def initialize(logger_)
      @logger = logger_
      @agent_interface = MatchAgentInterface.new
      @match_communicator = Null.new

      @table_queues = {}
      ExhibitionConstants::GAMES.each do |game_definition_key, info|
        @table_queues[game_definition_key] = TableQueue.new(@match_communicator, @agent_interface, game_definition_key)
        # Enqueue matches that are waiting
        @table_queues[game_definition_key].my_matches.not_running.and.not_started.each do |m|
          match = @table_queues[game_definition_key].enqueue! m.id.to_s, m.dealer_options
          if match
            Timeout::timeout(THREE_MINUTES) do
              @table_queues[game_definition_key].start_players! match
            end
          end
        end
      end

      @syncer = Mutex.new

      @maintaining_ = false

      log(__method__)
    end

    def maintaining?() @maintaining_ end

    THREE_MINUTES = 180

    def maintain!
      @maintaining_ = true
      maintenance_logger = Logger.from_file_name(
        File.join(
          ApplicationDefs::LOG_DIRECTORY,
          'table_manager.maintenance.log'
        )
      ).with_metadata!
      log(__method__, {started_maintenance_thread: true})
      loop do
        log_with maintenance_logger, __method__, msg: "Going to sleep"
        sleep MAINTENANCE_INTERVAL
        log_with maintenance_logger, __method__, msg: "Starting maintenance"

        begin
          started_match = {}
          do_update_match_queue = false
          @syncer.synchronize do
            @table_queues.each do |key, queue|
              if (
                queue.change_in_number_of_running_matches? do
                  started_match[key] = queue.check_queue!
                end
              )
                do_update_match_queue = true
              end
            end
          end
          started_match.each do |key, match|
            if match
              Timeout::timeout(THREE_MINUTES) do
                @table_queues[key].start_players! match
              end
            end
          end
          if do_update_match_queue
            @match_communicator.update_match_queue!
          end
          clean_up_matches!
        rescue => e
          handle_exception nil, e
          Rusen.notify e # Send an email notification
        end
        log_with maintenance_logger, __method__, msg: "Finished maintenance"
      end
    end

    def kill_match!(match_id)
      log(__method__, match_id: match_id)

      @syncer.synchronize do
        @table_queues.each do |key, queue|
          if (
            queue.change_in_number_of_running_matches? do
              queue.kill_match!(match_id)
            end
          )
            @match_communicator.update_match_queue!
          end
        end
      end
    end

    def clean_up_matches!
      Match.delete_matches_older_than! 1.day
    end

    def enque_match!(match_id, options)
      begin
        m = Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound
        return kill_match!(match_id)
      else
        started_match = {}
        do_update_match_queue = false
        @syncer.synchronize do
          if (
            @table_queues[m.game_definition_key.to_s].change_in_number_of_running_matches? do
              started_match[m.game_definition_key.to_s] = @table_queues[m.game_definition_key.to_s].enqueue!(match_id, options)
            end
          )
            do_update_match_queue = true
          end
        end
        started_match.each do |key, match|
          if match
            Timeout::timeout(THREE_MINUTES) do
              @table_queues[key].start_players! match
            end
          end
        end
        if do_update_match_queue
          @match_communicator.update_match_queue!
        end
      end
    end

    def start_proxy!(match_id)
      begin
        match = Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound
        return kill_match!(match_id)
      else
        @agent_interface.start_proxy!(match) do |players_at_the_table|
          @match_communicator.match_updated! match_id.to_s
        end
      end
    end

    def play_action!(match_id, action)
      log __method__, {
        match_id: match_id,
        action: action
      }
      begin
        match = Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound
        log(
          __method__,
          {
            msg: "Request to play in match #{match_id} when no such proxy exists! Killed match.",
            match_id: match_id,
            action: action
          },
          Logger::Severity::ERROR
        )
        return kill_match!(match_id)
      end
      unless @table_queues[match.game_definition_key.to_s].running_matches[match_id]
        log(
          __method__,
          {
            msg: "Request to play in match #{match_id} in seat #{match.seat} when no such proxy exists! Killed match.",
            match_id: match_id,
            match_name: match.name,
            last_updated_at: match.updated_at,
            running?: match.running?,
            last_slice_viewed: match.last_slice_viewed,
            last_slice_present: match.slices.length - 1,
            action: action
          },
          Logger::Severity::ERROR
        )
        return kill_match!(match_id)
      end
      log __method__, {
        match_id: match_id,
        action: action,
        running?: !@table_queues[match.game_definition_key.to_s].running_matches[match_id].nil?
      }
      proxy = @table_queues[match.game_definition_key.to_s].running_matches[match_id][:proxy]
      unless proxy
        log(
          __method__,
          {
            msg: "Request to play in match #{match_id} in seat #{match.seat} when no such proxy exists! Killed match.",
            match_id: match_id,
            match_name: match.name,
            last_updated_at: match.updated_at,
            running?: match.running?,
            last_slice_viewed: match.last_slice_viewed,
            last_slice_present: match.slices.length - 1,
            action: action
          },
          Logger::Severity::ERROR
        )
        return kill_match!(match_id)
      end

      @agent_interface.play!(action, match, proxy) do |players_at_the_table|
        @match_communicator.match_updated! match_id
        if players_at_the_table.match_state.first_state_of_first_round?
          @match_communicator.update_match_queue!
        end
      end

      kill_match!(match_id) if proxy.match_ended?
    end
  end

  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false, backtrace: false

    attr_accessor :maintainer

    def perform(request)
      @maintainer.maintain! unless @maintainer.maintaining?
    end
  end

  class StatefulWorker
    include SimpleLogging
    include ParamRetrieval
    include HandleException

    attr_accessor :maintainer

    def initialize
      @logger = Logger.from_file_name(
        File.join(
          ApplicationDefs::LOG_DIRECTORY,
          'table_manager.log'
        )
      ).with_metadata!
      log __method__, 'Starting new TMSW'
      @maintainer = Maintainer.new @logger
    end

    # Called by Rails controller through Sidekiq
    def perform(request, params=nil)
      match_id = nil
      begin
        log(__method__, {request: request, params: params})

        case request
        # when START_MATCH_REQUEST_CODE
          # @todo Put bots in erb yaml and have them reread here
        when DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
          return @maintainer.clean_up_matches!
        end

        match_id = retrieve_match_id_or_raise_exception params

        log(__method__, {request: request, match_id: match_id})

        do_request!(request, match_id, params)
      rescue => e
        handle_exception match_id, e
        Rusen.notify e # Send an email notification
      end
    end

    def call(worker, msg, queue)
      log __method__, msg: msg
      if msg['args'].first == 'maintain'
        worker.maintainer = self.maintainer
        yield
      else
        perform *msg['args']
      end
    end

    protected

    def do_request!(request, match_id, params)
      case request
      when START_MATCH_REQUEST_CODE
        log(__method__, {request: request, match_id: match_id, msg: 'Enqueueing match'})

        @maintainer.enque_match!(
          match_id,
          retrieve_parameter_or_raise_exception(params, OPTIONS_KEY)
        )
      when START_PROXY_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Starting proxy'
        )

        @maintainer.start_proxy! match_id
      when PLAY_ACTION_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Taking action'
        )

        @maintainer.play_action! match_id, retrieve_parameter_or_raise_exception(params, ACTION_KEY)
      when KILL_MATCH
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: "Killing match #{match_id}"
        )
        @maintainer.kill_match! match_id
      else
        raise StandardError.new("Unrecognized request: #{request}")
      end
    end
  end

  class Factory
    @instance = nil
    def initialize
      @instance ||= StatefulWorker.new
    end
    def new() @instance end
  end
end
