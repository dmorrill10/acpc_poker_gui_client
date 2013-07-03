
# @todo Try moving to config/initializers to remove inane const_defined? checks that only serve to quiet warning messages.

# require each bot runner class
Dir.glob("#{File.expand_path('../../', __FILE__)}/lib/bots/run_*_bot.rb").each do |runner_class|
  begin
    require runner_class
  rescue
  end
end

require 'socket'
require 'acpc_dealer'
require_relative '../app/models/user'

# Assortment of constant definitions.
module ApplicationDefs
  # @return [String] Improper amount warning message.
  IMPROPER_AMOUNT_MESSAGE = "Improper amount entered" unless const_defined?(:IMPROPER_AMOUNT_MESSAGE)

  DEALER_MILLISECOND_TIMEOUT = 7 * 24 * 3600000 unless const_defined? :DEALER_MILLISECOND_TIMEOUT

  DEFAULT_BOT_NAME = 'Tester' unless const_defined? :DEFAULT_BOT_NAME

  STATIC_GAME_DEFINITIONS = {
    two_player_nolimit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:nolimit],
      text: '2-player no-limit',
      opponents: {DEFAULT_BOT_NAME => RunTestingBot},
      num_players: 2
    },
    two_player_limit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:limit],
      text: '2-player limit',
      opponents: {DEFAULT_BOT_NAME => RunTestingBot},
      num_players: 2
    },
    three_player_nolimit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[3][:nolimit],
      text: '3-player no-limit',
      opponents: {DEFAULT_BOT_NAME => RunTestingBot, 'Tester2' => RunTestingBot},
      num_players: 3
    },
    three_player_limit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[3][:limit],
      text: '3-player limit',
      opponents: {DEFAULT_BOT_NAME => RunTestingBot, 'Tester2' => RunTestingBot},
      num_players: 3
    }
  } unless const_defined? :GAME_DEFINITIONS

  # Human opponent names map to nil
  def self.game_definitions
    lcl_game_defs = STATIC_GAME_DEFINITIONS.dup
    lcl_game_defs.each do |type, prop|
      User.each do |user|
        prop[:opponents].merge! user.name => nil
      end
    end
  end

  LOG_DIRECTORY = File.expand_path('../../log', __FILE__) unless const_defined? :LOG_DIRECTORY

  MATCH_LOG_DIRECTORY = File.join(LOG_DIRECTORY, 'match_logs') unless const_defined? :MATCH_LOG_DIRECTORY

  START_MATCH_REQUEST_CODE = 'dealer' unless const_defined? :START_MATCH_REQUEST_CODE
  START_PROXY_REQUEST_CODE = 'proxy' unless const_defined? :START_PROXY_REQUEST_CODE
  PLAY_ACTION_REQUEST_CODE = 'play' unless const_defined? :PLAY_ACTION_REQUEST_CODE

  # @return [Array<Class>] Returns only the names that correspond to bot runner
  #   classes as those classes.
  def self.bots(game_def_key, player_names)
    player_names.map do |name|
      game_definitions[game_def_key][:opponents][name]
    end.reject { |elem| elem.nil? }
  end
  def self.random_seat(num_players)
    rand(num_players) + 1
  end
  def self.random_seed
    random_float = rand
    random_int = (random_float * 10**random_float.to_s.length).to_i
  end
end