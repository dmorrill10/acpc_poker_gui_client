require 'thread'
require_relative 'table_manager/table_manager'
using TableManager::MonkeyPatches::IntegerAsProcessId

# Email on error
require_relative 'setup_rusen'

# For job scheduling
require 'sidekiq'

require_relative '../../lib/simple_logging'
using SimpleLogging::MessageFormatting

module TableManager
  class Maintainer
    include SimpleLogging
    include MatchInterface
    include ParamRetrieval

    MAINTENANCE_INTERVAL = 60 # seconds

    def initialize(logger_)
      @logger = logger_
      @agent_interface = MatchAgentInterface.new(@logger)
      @match_communicator = MatchCommunicator.new

      @table_queue = TableQueue.new(@match_communicator, @agent_interface, @logger)

      @syncer = Mutex.new

      log(__method__)
    end

    def maintain!
      @thread = Thread.new do
        @logger = Logger.from_file_name(
          File.join(
            ApplicationDefs::LOG_DIRECTORY,
            'table_manager.maintenance.log'
          )
        ).with_metadata!
        loop do
          log __method__, msg: "Going to sleep"
          sleep MAINTENANCE_INTERVAL
          log __method__, msg: "Starting maintenance"
          clean_up_matches!
          log __method__, msg: "Finished maintenance"
        end
      end
      log(__method__, {started_thread: @thread})
    end

    def kill_match!(match_id)
      log(__method__, match_id: match_id)

      @syncer.synchronize do
        if (
          @table_queue.changeInNumberOfRunningMatches? do
            @table_queue.kill_match!(match_id)
          end
        )
          @match_communicator.update_match_queue!
        end
      end
    end

    def clean_up_matches!
      @syncer.synchronize do
        if (
          @table_queue.changeInNumberOfRunningMatches? do
            @table_queue.check_queue!
          end
        )
          @match_communicator.update_match_queue!
        end

        log __method__, num_matches_in_database_after: Match.all.length
      end
    end

    def enque_match!(match_id, options)
      @syncer.synchronize do
        if (
          @table_queue.changeInNumberOfRunningMatches? do
            @table_queue.enque!(match_id, options)
          end
        )
          @match_communicator.update_match_queue!
        end
      end
    end

    def start_proxy!(match_id)
      @syncer.synchronize do
        match = match_instance(match_id)
        @agent_interface.start_proxy!(match) do |players_at_the_table|
          @match_communicator.match_updated! match_id.to_s
        end
      end
    end

    def play_action!(match_id, action)
      @syncer.synchronize do
        unless @table_queue.running_matches[match_id]
          raise StandardError.new(
            "Request to play in match #{match_id} when it doesn't exist!"
          )
        end
        match = match_instance(match_id)
        proxy = @table_queue.running_matches[match_id][:proxy]
        unless proxy
          raise StandardError.new(
            "Ignoring request to play in match #{match_id} in seat #{match.seat} when no such proxy exists."
          )
        end

        log __method__, {
          match_id: match_id,
          num_tables: @table_queue.running_matches.length,
          action: action
        }

        @agent_interface.play!(action, match, proxy) do |players_at_the_table|
          @match_communicator.match_updated! match_id
          if players_at_the_table.match_state.first_state_of_first_round?
            @match_communicator.update_match_queue!
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
          @table_queue.kill_match!(match.id)
          @table_queue.check_queue!
          @match_communicator.update_match_queue!
        end
      end
    end
  end

  class Worker
    include Sidekiq::Worker
    sidekiq_options retry: false, backtrace: true

    include SimpleLogging # Must be after Sidekiq::Worker to log to the proper file
    include MatchInterface
    include ParamRetrieval

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
        @@maintainer = Maintainer.new @@logger
        @@maintainer.maintain!
      end
      @logger = @@logger
    end

    def refresh_module(module_constant, module_file, mode_file_base)
      if Object.const_defined?(module_constant)
        Object.send(:remove_const, module_constant)
      end
      $".delete_if {|s| s.include?(mode_file_base) }
      load module_file

      log __method__, msg: "RELOADED #{module_constant}"
    end

    # Called by Rails controller through Sidekiq
    def perform(request, params=nil)
      begin
        log(__method__, {request: request, params: params})

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
