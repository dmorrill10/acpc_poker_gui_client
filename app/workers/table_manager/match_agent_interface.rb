# Proxy to connect to the dealer
require_relative '../web_application_player_proxy'
require 'acpc_poker_types'
require 'acpc_dealer'

# For an opponent bot
require 'process_runner'

require_relative '../../../lib/database_config'
require_relative '../../models/match'

require_relative 'match_interface'

require_relative '../../../lib/simple_logging'
using SimpleLogging::MessageFormatting

# In case the dealer or another process fails
# to start properly
require 'timeout'

module TableManager
  class MatchAgentInterface
    include AcpcPokerTypes
    include SimpleLogging
    include MatchInterface

    def initialize
      @logger = Logger.from_file_name(
        File.join(
          ApplicationDefs::LOG_DIRECTORY,
          'table_manager.mai.log'
        )
      ).with_metadata!
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
      dealer_info = Timeout::timeout(1) do
        AcpcDealer::DealerRunner.start(
          dealer_arguments,
          MATCH_LOG_DIRECTORY,
          port_numbers
        )
      end

      # Store the port numbers in the database so the web app can access them
      match.port_numbers = dealer_info[:port_numbers]
      save_match_instance! match

      dealer_info
    end

    def start_opponents!(bot_start_commands)
      log __method__, num_opponents: bot_start_commands.length

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
          command_to_be_run: bot_start_command.join(' ')
        }
      )
      pid = Timeout::timeout(1) do
        ProcessRunner.go(bot_start_command)
      end
      log(
        __method__,
        {
          bot_started?: true,
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
end

