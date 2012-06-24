
# require each bot runner class
Dir.glob("#{Dir.pwd}/lib/bots/run_*_bot.rb").each do |runner_class|
  require runner_class
end

# Assortment of constant definitions.
module ApplicationDefs

  # @return [String] Improper amount warning message.
  IMPROPER_AMOUNT_MESSAGE = "Improper amount entered"

  GAME_DEFINITIONS = {
    two_player_limit: {
      file: File.expand_path('../../external/project_acpc_server/holdem.limit.2p.reverse_blinds.game', __FILE__),
      text: '2-player Limit',
      bots: {'tester' => RunTestingBot}
    },
    two_player_nolimit: {
      file: File.expand_path('../../external/project_acpc_server/holdem.nolimit.2p.200BB.reverse_blinds.game', __FILE__),
      text: '2-player no-limit',
      bots: {
        'UAlberta2012' => RunUAlberta2012Bot,
        'UAlberta2011' => RunUAlberta2011Bot,
        'tester' => RunTestingBot
      }
    }
  }
end
