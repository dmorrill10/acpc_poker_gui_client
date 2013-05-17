
# require each bot runner class
Dir.glob("#{File.expand_path('../../', __FILE__)}/lib/bots/run_*_bot.rb").each do |runner_class|
  begin
    require runner_class
  rescue
  end
end

require 'acpc_dealer'

# Assortment of constant definitions.
module ApplicationDefs

  # @return [String] Improper amount warning message.
  IMPROPER_AMOUNT_MESSAGE = "Improper amount entered" unless const_defined?(:IMPROPER_AMOUNT_MESSAGE)

  DEALER_MILLISECOND_TIMEOUT = 7 * 24 * 3600000 unless const_defined? :DEALER_MILLISECOND_TIMEOUT

  GAME_DEFINITIONS = {
    two_player_nolimit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:nolimit],
      text: '2-player no-limit',
      bots: {'tester' => RunTestingBot},
      num_players: 2
    },
    two_player_limit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:limit],
      text: '2-player limit',
      bots: {'tester' => RunTestingBot},
      num_players: 2
    }
  } unless const_defined? :GAME_DEFINITIONS

  LOG_DIRECTORY = File.expand_path('../../log', __FILE__) unless const_defined? :LOG_DIRECTORY

  MATCH_LOG_DIRECTORY = File.join(LOG_DIRECTORY, 'match_logs') unless const_defined? :MATCH_LOG_DIRECTORY

  # @return [Array<Class>] Returns only the names that correspond to bot runner
  #   classes as those classes.
  def self.bots(game_def_key, player_names)
    player_names.map do |name|
      GAME_DEFINITIONS[game_def_key][:bots][name]
    end.reject { |elem| elem.nil? }
  end
  def self.random_seat(num_players)
    rand(num_players) + 1
  end
  def self.users_seat_index(game_def_key, player_names)
    player_names.index do |name|
      GAME_DEFINITIONS[game_def_key][:bots][name].nil?
    end
  end
end
