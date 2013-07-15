# require each bot runner class
Dir.glob("#{File.expand_path('../', __FILE__)}/run_*.rb").each do |runner_class|
  begin
    require runner_class
  rescue
  end
end
require_relative '../app/models/user'
require 'acpc_dealer'

# Assortment of constant definitions.
module ApplicationDefs
  DEFAULT_BOT_NAME = 'Tester' unless const_defined? :DEFAULT_BOT_NAME

  STATIC_GAME_DEFINITIONS = {
    two_player_nolimit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:nolimit],
      text: '2-player no-limit',
      opponents: {
        DEFAULT_BOT_NAME => RunTestingBot,
        # ADD BOTS HERE LIKE SO:
        # 'YourAgentNameForDropdownAndLogs' => RunYourAgentBot
      },
      num_players: 2
    },
    two_player_limit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[2][:limit],
      text: '2-player limit',
      opponents: {
        DEFAULT_BOT_NAME => RunTestingBot,
        # ADD BOTS HERE LIKE SO:
        # 'YourAgentNameForDropdownAndLogs' => RunYourAgentBot
      },
      num_players: 2
    },
    three_player_nolimit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[3][:nolimit],
      text: '3-player no-limit',
      opponents: {
        DEFAULT_BOT_NAME => RunTestingBot,
        'Tester2' => RunTestingBot,
        # ADD BOTS HERE LIKE SO:
        # 'YourAgentNameForDropdownAndLogs' => RunYourAgentBot
      },
      num_players: 3
    },
    three_player_limit: {
      file: AcpcDealer::GAME_DEFINITION_FILE_PATHS[3][:limit],
      text: '3-player limit',
      opponents: {
        DEFAULT_BOT_NAME => RunTestingBot,
        'Tester2' => RunTestingBot,
        # ADD BOTS HERE LIKE SO:
        # 'YourAgentNameForDropdownAndLogs' => RunYourAgentBot
      },
      num_players: 3
    }
  } unless const_defined? :STATIC_GAME_DEFINITIONS

  # Human opponent names map to nil
  def self.game_definitions
    lcl_game_defs = STATIC_GAME_DEFINITIONS.dup
    lcl_game_defs.each do |type, prop|
      User.each do |user|
        prop[:opponents].merge! user.name => nil
      end
    end
  end
end