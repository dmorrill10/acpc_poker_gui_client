# @todo Although my initial ideas was to make this a thread-safe table queue,
# it seems safer and more efficient to move the lock out to the user of this
# class.

# Proxy to connect to the dealer
require_relative '../web_application_player_proxy'
require 'acpc_poker_types'
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

require_relative '../../../lib/database_config'
require_relative '../../models/match'

require_relative '../../../lib/simple_logging'
using SimpleLogging::MessageFormatting


require_relative 'table_manager_constants'
require_relative 'monkey_patches'
using TableManager::MonkeyPatches::IntegerAsProcessId

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module TableManager
  class TableQueue
    include SimpleLogging

    attr_reader :running_matches

    exceptions :no_port_for_dealer_available

    def initialize(match_communicator_, agent_interface_, game_definition_key_)
      @match_communicator = match_communicator_
      @agent_interface = agent_interface_
      @logger = Logger.from_file_name(
        File.join(
          ApplicationDefs::LOG_DIRECTORY,
          'table_manager.queue.log'
        )
      ).with_metadata!
      @matches_to_start = []
      @running_matches = {}
      @game_definition_key = game_definition_key_

      log(
        __method__,
        {
          game_definition_key: @game_definition_key,
          max_num_matches: ExhibitionConstants::GAMES[@game_definition_key]['MAX_NUM_MATCHES']
        }
      )

      # Clean up old matches
      my_matches.running_or_started.each do |m|
        m.delete
      end
    end

    def start_players!(match)
      opponents = []
      match.every_bot(DEALER_HOST) do |bot_command|
        opponents << bot_command
      end

      if opponents.empty?
        kill_match! match.id.to_s
        raise StandardError.new("No opponents found to start for #{match.id.to_s}! Killed match.")
      end

      @agent_interface.start_opponents!(opponents)
      log(__method__, msg: "Opponents started for #{match.id.to_s}")

      @running_matches[match.id.to_s][:proxy] = @agent_interface.start_proxy!(match) do |players_at_the_table|
        @match_communicator.match_updated! match.id.to_s
      end
      self
    end

    def my_matches
      Match.where(game_definition_key: @game_definition_key.to_sym)
    end

    def change_in_number_of_running_matches?
      prevNumMatchesRunning = @running_matches.length
      yield if block_given?
      prevNumMatchesRunning != @running_matches.length
    end

    def length
      @matches_to_start.length
    end

    def ports_in_use
      @running_matches.values.inject([]) do |ports, m|
        if m[:dealer] && m[:dealer][:port_numbers]
          m[:dealer][:port_numbers].each { |n| ports << n.to_i }
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

    # @return (@see #dequeue!)
    def enqueue!(match_id, dealer_options)
      log(
        __method__,
        {
          match_id: match_id,
          running_matches: @running_matches.map { |r| r.first },
          game_definition_key: @game_definition_key,
          max_num_matches: ExhibitionConstants::GAMES[@game_definition_key]['MAX_NUM_MATCHES']
        }
      )

      if @running_matches[match_id]
        return log(
          __method__,
          msg: "Match #{match_id} already started!"
        )
      end

      @matches_to_start << {match_id: match_id, options: dealer_options}

      if @running_matches.length < ExhibitionConstants::GAMES[@game_definition_key]['MAX_NUM_MATCHES']
        return dequeue!
      end

      nil
    end

    # @return (@see #dequeue!)
    def check_queue!
      log __method__

      kill_matches!

      log __method__, {num_running_matches: @running_matches.length, num_matches_to_start: @matches_to_start.length}

      if @running_matches.length < ExhibitionConstants::GAMES[@game_definition_key]['MAX_NUM_MATCHES']
        return dequeue!
      end
      nil
    end

    # @todo Shouldn't be necessary, so this method isn't called right now, but I've written it so I'll leave it for now
    def fix_running_matches_statuses!
      log __method__
      my_matches.running do |m|
        if !(@running_matches[m.id.to_s] && AcpcDealer::dealer_running?(@running_matches[m.id.to_s][:dealer]))
          m.is_running = false
          m.save
        end
      end
    end

    def kill_match!(match_id)
      return unless match_id

      begin
        match = Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound
      else
        match.is_running = false
        match.save!
      end

      match_info = @running_matches[match_id]
      if match_info
        @running_matches.delete(match_id)
      end
      @matches_to_start.delete_if { |m| m[:match_id] == match_id }

      kill_dealer!(match_info[:dealer]) if match_info && match_info[:dealer]

      log __method__, match_id: match_id, msg: 'Match successfully killed'
    end

    protected

    def kill_dealer!(dealer_info)
      log(
        __method__,
        pid: dealer_info[:pid],
        was_running?: true,
        dealer_running?: AcpcDealer::dealer_running?(dealer_info)
      )

      if AcpcDealer::dealer_running? dealer_info
        dealer_info[:pid].kill_process

        sleep 1 # Give the dealer a chance to exit

        log(
          __method__,
          pid: dealer_info[:pid],
          msg: 'After TERM signal',
          dealer_still_running?: AcpcDealer::dealer_running?(dealer_info)
        )

        if AcpcDealer::dealer_running?(dealer_info)
          dealer_info[:pid].force_kill_process
          sleep 1

          log(
            __method__,
            pid: dealer_info[:pid],
            msg: 'After KILL signal',
            dealer_still_running?: AcpcDealer::dealer_running?(dealer_info)
          )

          if AcpcDealer::dealer_running?(dealer_info)
            raise(
              StandardError.new(
                "Dealer process #{dealer_info[:pid]} couldn't be killed!"
              )
            )
          end
        end
      end
    end

    def kill_matches!
      log __method__
      running_matches_array = @running_matches.to_a
      running_matches_array.each_index do |i|
        match_id, match_info = running_matches_array[i]

        unless (AcpcDealer::dealer_running?(match_info[:dealer]) && Match.id_exists?(match_id))
          log(
            __method__,
            {
              match_id_being_killed: match_id
            }
          )

          kill_match! match_id
        end
      end
      @matches_to_start.delete_if do |m|
        !Match.id_exists?(m[:match_id])
      end
    end

    def match_queued?(match_id)
      @matches_to_start.any? { |m| m[:match_id] == match_id }
    end

    def port(available_ports_)
      port_ = available_ports_.pop
      while !AcpcDealer::port_available?(port_)
        if available_ports_.empty?
          raise NoPortForDealerAvailable.new("None of the special ports (#{available_special_ports}) are open")
        end
        port_ = available_ports_.pop
      end
      unless port_
        raise NoPortForDealerAvailable.new("None of the special ports (#{available_special_ports}) are open")
      end
      port_
    end

    # @return [Object] The match that has been started or +nil+ if none could
    # be started. Note that players have
    # yet to be started, so the caller must do this.
    def dequeue!
      log(
        __method__,
        num_matches_to_start: @matches_to_start.length
      )
      return nil if @matches_to_start.empty?

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
      return self unless match_id

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
        if r then port(available_ports_) else 0 end
      end

      match.is_running = true
      match.save!

      num_repetitions = 0
      while @running_matches[match_id][:dealer].nil? do
        log(
          __method__,
          msg: "Added #{match_id} list of running matches",
          available_special_ports: available_ports_,
          special_port_requirements: special_port_requirements,
          :'ports_to_be_used_(zero_for_random)' => ports_to_be_used
        )
        begin
          @running_matches[match_id][:dealer] = @agent_interface.start_dealer!(
            options,
            match,
            ports_to_be_used
          )
        rescue Timeout::Error
          begin
            ports_to_be_used = special_port_requirements.map do |r|
              if r then port(available_ports_) else 0 end
            end
          rescue NoPortForDealerAvailable => e
            if num_repetitions < 1
              sleep 1
              num_repetitions += 1
              available_ports_ = available_special_ports
            else
              kill_match! match_id
              raise e
            end
          end
        end
      end

      begin
        match = Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound => e
        kill_match! match_id
        raise e
      end

      log(
        __method__,
        msg: "Dealer started for #{match_id} with pid #{@running_matches[match_id][:dealer][:pid]}",
        ports: match.port_numbers
      )

      match
    end
  end
end
