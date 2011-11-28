
# Assortment of constant definitions.
module ApplicationDefs

   # @return [String] Improper amount warning message.
   IMPROPER_AMOUNT_MESSAGE = "Improper amount entered"

   # @return [Hash<Symbol, String>] File names of the game definitions understood by this application.
   GAME_DEFINITION_FILE_NAMES = {
           holdem_limit_2p_reverse_blinds_game: File.expand_path('../../external/project_acpc_server/holdem.limit.2p.reverse_blinds.game', __FILE__)#,
           #:two_player_no_limit_texas_holdem_poker =>
           #        File.expand_path('external/project_acpc_server/holdem.nolimit.2p.reverse_blinds.game'),
           #:three_player_limit_texas_holdem_poker =>
           #        File.expand_path('external/project_acpc_server/holdem.limit.3p.game'),
           #:three_player_no_limit_texas_holdem_poker =>
           #        File.expand_path('external/project_acpc_server/holdem.nolimit.3p.game')
   }
   
   # @return [Hash<Symbol, String>] Names of the game definitions understood by this application.
   GAME_DEFINITION_NAMES = GAME_DEFINITION_FILE_NAMES.inject({}) do |names, symbol_file_array|
      (symbol, file_name) = symbol_file_array
      names[symbol] = file_name.split(/\//).last
      names
   end
end
