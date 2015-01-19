require 'thread'
require_relative 'table_manager/table_manager'
using TableManager::MonkeyPatches::IntegerAsProcessId

# Email on error
require_relative 'setup_rusen'

# For job scheduling
require 'sidekiq'
Sidekiq.configure_server do |config|
  config.poll_interval = 2
end

require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

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

      @table_queue = TableQueue.new(@match_communicator, @agent_interface)

      @syncer = Mutex.new

      @maintaining_ = false

      log(__method__)
    end

    def maintaining?() @maintaining_ end

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
          @syncer.synchronize do
            if (
              @table_queue.change_in_number_of_running_matches? do
                @table_queue.check_queue!
              end
            )
              @match_communicator.update_match_queue!
            end
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
        if (
          @table_queue.change_in_number_of_running_matches? do
            @table_queue.kill_match!(match_id)
          end
        )
          @match_communicator.update_match_queue!
        end
      end
    end

    def clean_up_matches!
      Match.delete_matches_older_than! 1.day
    end

    def enque_match!(match_id, options)
      @syncer.synchronize do
        if (
          @table_queue.change_in_number_of_running_matches? do
            @table_queue.enqueue!(match_id, options)
          end
        )
          @match_communicator.update_match_queue!
        end
      end
    end

    def start_proxy!(match_id)
      match = Match.find match_id
      @agent_interface.start_proxy!(match) do |players_at_the_table|
        @match_communicator.match_updated! match_id.to_s
      end
    end

    def play_action!(match_id, action)
      log __method__, {
        match_id: match_id,
        action: action,
        running?: !@table_queue.running_matches[match_id].nil?
      }
      unless @table_queue.running_matches[match_id]
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
        else
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
        end
        return kill_match!(match_id)
      end
      match = Match.find match_id
      proxy = @table_queue.running_matches[match_id][:proxy]
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

    include SimpleLogging # Must be after Sidekiq::Worker to log to the proper file
    include ParamRetrieval
    include HandleException

    def initialize
      @@logger ||= nil
      @@maintainer ||= nil
      unless @@maintainer
        @@logger = Logger.from_file_name(
          File.join(
            ApplicationDefs::LOG_DIRECTORY,
            'table_manager.log'
          )
        ).with_metadata!
        @logger = @@logger
        log(__method__, "Creating new TMM")
        @@maintainer = Maintainer.new @@logger
      end
      @logger = @@logger
      log(__method__, "Started new TMW")
    end

    # Called by Rails controller through Sidekiq
    def perform(request, params=nil)
      sleep 2
      match_id = nil
      begin
        log(__method__, {request: request, params: params})

        case request
        when 'maintain'
          log(__method__, {maintaining?: @@maintainer.maintaining?})
          @@maintainer.maintain! unless @@maintainer.maintaining?
          return
        # when START_MATCH_REQUEST_CODE
          # @todo Put bots in erb yaml and have them reread here
        when DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
          return @@maintainer.clean_up_matches!
        end

        match_id = retrieve_match_id_or_raise_exception params

        log(__method__, {request: request, match_id: match_id})

        do_request!(request, match_id, params)
      rescue => e
        handle_exception match_id, e
        Rusen.notify e # Send an email notification
      end
    end

    protected

    def do_request!(request, match_id, params)
      case request
      when START_MATCH_REQUEST_CODE
        log(__method__, {request: request, match_id: match_id, msg: 'Enqueueing match'})

        @@maintainer.enque_match!(
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

        @@maintainer.start_proxy! match_id
      when PLAY_ACTION_REQUEST_CODE
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: 'Taking action'
        )

        @@maintainer.play_action! match_id, retrieve_parameter_or_raise_exception(params, ACTION_KEY)
      when KILL_MATCH
        log(
          __method__,
          request: request,
          match_id: match_id,
          msg: "Killing match #{match_id}"
        )
        @@maintainer.kill_match! match_id
      else
        raise StandardError.new("Unrecognized request: #{request}")
      end
    end
  end
end
# Want to instantiate one worker upon starting
TableManager::Worker.perform_async 'maintain'
