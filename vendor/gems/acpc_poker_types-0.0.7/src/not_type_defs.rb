
# Assortment of constant definitions and methods for generating default values.
module NotTypeDefs
   # @return [Boolean] Debugging mode switch.
   DEBUG = true
   
   # @return [Integer] The user's index in the array of Player.
   USERS_INDEX = 0;
   
   # @return [String] The ACPC dealer version label.
   VERSION_LABEL = 'VERSION'

   # @return [Hash] The ACPC dealer version numbers.
   VERSION_NUMBERS = {:major => 2, :minor => 0, :revision => 0}
   
   # @return [Hash] Reversed blind positions relative to the dealer (used in a heads up (2 player) game).
   BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS = {:submits_big_blind => 0, :submits_small_blind => 1}
   
   # @return [Hash] Normal blind positions relative to the dealer.
   BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS = {:submits_big_blind => 1, :submits_small_blind => 0}

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

   # @return [String] Dealer specified string terminator.
   TERMINATION_STRING = '\r\n'
end
