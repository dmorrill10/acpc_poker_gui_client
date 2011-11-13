
# Assortment of constant definitions and methods for generating default values.
module ApplicationDefs
   # @return [Boolean] Debugging mode switch.
   DEBUG = true
   
   # @return [Integer] The user's index in the array of Player.
   USERS_INDEX = 0;
   
   # @return [String] This application's version label.
   VERSION_LABEL = 'VERSION'

   # @return [Hash] This application's current version numbers.
   VERSION_NUMBERS = {:major => 2, :minor => 0, :revision => 0}

   # @return [Hash] Maximum game parameter values.
   MAX_VALUES = {:rounds => 4, :players => 10, :board_cards => 7, :hole_cards => 3, :number_of_actions => 64,
                 :line_length => 1024}

   # @return [Hash] Betting types understood by this application.
   BETTING_TYPES = {:limit => 'limit', :nolimit => 'nolimit'}
   
   # @return [Hash] Action types understood by this application.
   ACTION_TYPES = {:fold => 'f', :call => 'c', :raise => 'r'}
   
   # @return [Hash] Numeric representation of each action type.
   ACTION_TYPE_NUMBERS = {'f' => 0, 'c' => 1, 'r' => 2}
   
   # @return [Hash] Card ranks understood by this application.
   CARD_RANKS = {:two => '2', :three => '3', :four => '4', :five => '5', :six => '6', :seven => '7', :eight => '8',
                 :nine => '9', :ten => 'T', :jack => 'J', :queen => 'Q', :king => 'K', :ace => 'A'}
   
   # @return [Hash] Numeric representation of each card rank (though not the
   #     numeric version of the rank).
   # @example The numeric representation of rank +'2'+ is +0+, not +2+.
   #     CARD_RANK_NUMBERS['2'] == 0
   CARD_RANK_NUMBERS = {'2' => 0, '3' => 1, '4' => 2, '5' => 3, '6' => 4,
      '7' => 5, '8' => 6, '9' => 7, 'T' => 8, 'J' => 9, 'Q' => 10, 'K' => 11,
      'A' => 12}

   # @return [Hash] Card suits understood by this application.
   CARD_SUITS = {:spades => 's', :hearts => 'h', :diamonds => 'd', :clubs => 'c'}
   
   # @return [Hash] Numeric representation of each card suit.
   CARD_SUIT_NUMBERS = {'c' => 0, 'd' => 1, 'h' => 2, 's' => 3}
   
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

   # @return [String]  Label for match state strings.
   MATCH_STATE_LABEL = 'MATCHSTATE'

   # @return [Array] A list of all the cards understood by this application.
   LIST_OF_CARDS = CARD_RANKS.values.map {|rank| CARD_SUITS.values.map {|suit| rank + suit}}.flatten

   # @return [Array] A list of all the hole cards understood by this application.
   LIST_OF_HOLE_CARD_HANDS =
           LIST_OF_CARDS.map {|first_card| LIST_OF_CARDS.map {|second_card| first_card + second_card}}.flatten

   # @return [Integer] The maximum value of an eight bit unsigned integer.
   UINT8_MAX = 2**8 - 1

   # @return [Integer] The maximum value of a 32 bit signed integer.
   INT32_MAX = 2**31 - 1

   # @return [String] A newline character.
   NEWLINE = "\n"
   
   # @return [String] Dealer specified string terminator.
   TERMINATION_STRING = '\r\n'
   
   # @return [Array] The default first player position in each round.
   def default_first_player_position_in_each_round
      first_player_position_in_each_round = []
      MAX_VALUES[:rounds].times do
         first_player_position_in_each_round << 1
      end
      first_player_position_in_each_round
   end
   
   # @return [Array] The default maximum raise in each round.
   def default_max_raise_in_each_round
      max_raise_in_each_round = []
      MAX_VALUES[:rounds].times do
         max_raise_in_each_round << UINT8_MAX
      end
      max_raise_in_each_round
   end
   
   # @param [Integer] number_of_players The number of players that require stacks.
   # @return [Array] The default list of initial stacks for every player.
   def default_list_of_player_stacks(number_of_players)
      list_of_player_stacks = []
      number_of_players.times do
         list_of_player_stacks << INT32_MAX
      end
      list_of_player_stacks
   end
   
   # TODO Move to ApplicationHelpers
   
   # Prints a given string prepended by the current class name if +DEBUG+ is true.
   #
   # @param [#to_s] object The object to print.
   def log(object)
      puts "#{get_class_name}: #{object}" if DEBUG
   end

   # Gets the current class name.
   #
   # @return [String] The current class name.
   def get_class_name
      self.class
   end
end
