
# Local modules
require File.expand_path('../../helpers/game_definition_helper', __FILE__)
require File.expand_path('../../acpc_poker_types_defs', __FILE__)
require File.expand_path('../../helpers/acpc_poker_types_helper', __FILE__)

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Class that parses and manages game definition information from a game definition file.
class GameDefinition
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   include GameDefinitionHelper
   
   exceptions :game_definition_parse_error
      
   # @return [String] The string designating the betting type.
   attr_reader :betting_type
   
   # @return [Integer] The number of players.
   attr_reader :number_of_players
      
   # @return [Integer] The number of rounds.
   attr_reader :number_of_rounds
      
   # @return [Array] The number of board cards in each round.
   # @example The usual Texas hold'em sequence would look like this:
   #     number_of_board_cards_in_each_round == [0, 3, 1, 1]
   attr_reader :number_of_board_cards_in_each_round
      
   # @return [Array] The minimum raise size in each round.
   attr_reader :raise_size_in_each_round
      
   # @return [Array] The position relative to the dealer that is first to act
   #     in each round, indexed from 1.
   # @example The usual Texas hold'em sequence would look like this:
   #     first_player_position_in_each_round == [2, 1, 1, 1]
   attr_reader :first_player_position_in_each_round
   
   # @return [Array] The maximum raise size in each round.
   attr_reader :max_raise_in_each_round
   
   # @return [Array] The list containing the initial stack size for every player.
   attr_reader :list_of_player_stacks
   
   # @return [Integer] The number of suits in the deck.
   attr_reader :number_of_suits
   
   # @return [Integer] The number of ranks in the deck.
   attr_reader :number_of_ranks
   
   # @return [Integer] The number of hole cards that each player is dealt.
   attr_reader :number_of_hole_cards
   
   # @return [Array] The array containing the blind sizes.
   attr_reader :list_of_blinds

   # @param [String] game_definition_file_name The name of the game definition file that this instance should parse.
   # @raise GameDefinitionParseError
   def initialize(game_definition_file_name)
      initialize_members!
      begin
         parse_game_definition! game_definition_file_name
      rescue => unable_to_read_or_open_file_error
         raise GameDefinitionParseError, unable_to_read_or_open_file_error.message
      end
      
      @list_of_player_stacks = default_list_of_player_stacks(@number_of_players) if @list_of_player_stacks.empty?

      sanity_check_game_definitions
   end
   
   # @return [String] The game definition in text format.
   def to_s
      list_of_lines = []
      list_of_lines << @betting_type if @betting_type
      list_of_lines << "stack = #{@list_of_player_stacks.join(' ')}" unless @list_of_player_stacks.empty?
      list_of_lines << "numPlayers = #{@number_of_players}" if @number_of_players
      list_of_lines << "blind = #{@list_of_blinds.join(' ')}" unless @list_of_blinds.empty?
      list_of_lines << "raiseSize = #{@raise_size_in_each_round.join(' ')}" unless @raise_size_in_each_round.empty?
      list_of_lines << "numRounds = #{@number_of_rounds}" if @number_of_rounds
      list_of_lines << "firstPlayer = #{@first_player_position_in_each_round.join(' ')}" unless @first_player_position_in_each_round.empty?
      list_of_lines << "maxRaises = #{@max_raise_in_each_round.join(' ')}" unless @max_raise_in_each_round.empty?
      list_of_lines << "numSuits = #{@number_of_suits}" if @number_of_suits
      list_of_lines << "numRanks = #{@number_of_ranks}" if @number_of_ranks
      list_of_lines << "numHoleCards = #{@number_of_hole_cards}" if @number_of_hole_cards
      list_of_lines << "numBoardCards = #{@number_of_board_cards_in_each_round.join(' ')}" unless @number_of_board_cards_in_each_round.empty?
      list_of_lines.join(NEWLINE)
   end
   
   # @return [Integer] The big blind.
   def big_blind      
      @list_of_blinds.max
   end
   
   # @return [Integer] The small blind.
   def small_blind
      @list_of_blinds.min
   end

   private
   
   def initialize_members!      
      @betting_type = BETTING_TYPES[:limit]
      @list_of_blinds = []
      @number_of_board_cards_in_each_round = []
      @raise_size_in_each_round = []
      @first_player_position_in_each_round = DEFAULT_FIRST_PLAYER_POSITION_IN_EVERY_ROUND
      @max_raise_in_each_round = DEFAULT_MAX_RAISE_IN_EACH_ROUND
      @list_of_player_stacks = []
   end

   def parse_game_definition!(game_definition_file_name)      
      for_every_line_in_file game_definition_file_name do |line|
         break if line.match(/\bend\s*gamedef\b/i)
         next if game_def_line_not_informative? line
         
         @betting_type = BETTING_TYPES[:limit] if line.match(/\b#{BETTING_TYPES[:limit]}\b/i)
         @betting_type = BETTING_TYPES[:nolimit] if line.match(/\b#{BETTING_TYPES[:nolimit]}\b/i)
         
         @list_of_player_stacks = check_game_def_line_for_definition line, 'stack', @list_of_player_stacks
         @number_of_players = check_game_def_line_for_definition line, 'numplayers', @number_of_players         
         @list_of_blinds = check_game_def_line_for_definition line, 'blind', @list_of_blinds
         @raise_size_in_each_round = check_game_def_line_for_definition line, 'raisesize', @raise_size_in_each_round
         @number_of_rounds = check_game_def_line_for_definition line, 'numrounds', @number_of_rounds
         @first_player_position_in_each_round = check_game_def_line_for_definition line, 'firstplayer', @first_player_position_in_each_round
         @max_raise_in_each_round = check_game_def_line_for_definition line, 'maxraises', @max_raise_in_each_round
         @number_of_suits = check_game_def_line_for_definition line, 'numsuits', @number_of_suits
         @number_of_ranks = check_game_def_line_for_definition line, 'numranks', @number_of_ranks
         @number_of_hole_cards = check_game_def_line_for_definition line, 'numholecards', @number_of_hole_cards
         @number_of_board_cards_in_each_round = check_game_def_line_for_definition line, 'numboardcards', @number_of_board_cards_in_each_round
      end      
   end
   
   # @raise GameDefinitionParseError
   def sanity_check_game_definitions     
      error_message = ""
      begin
         # Make sure that everything is defined that needs to be defined
         error_message = "list of player stacks not specified" unless @list_of_player_stacks
         error_message = "list of blinds not specified" unless @list_of_blinds
         error_message = "raise size in each round not specified" unless @raise_size_in_each_round
         error_message = "first player position in each round not specified" unless @first_player_position_in_each_round
         error_message = "maximum raise in each round not specified" unless @max_raise_in_each_round
         error_message = "number of board cards in each round not specified" unless @number_of_board_cards_in_each_round      
         
         # Do all the same checks that the dealer does
         error_message = "Invalid number of rounds: #{@number_of_rounds}" if invalid_number_of_rounds?
         error_message = "Invalid number of players: #{@number_of_players}" if invalid_number_of_players?
         error_message = "Only read #{@list_of_player_stacks.length} stack sizes, need #{@number_of_players}" if not_enough_player_stacks?
         error_message = "only read #{@list_of_blinds.length} blinds, need #{@number_of_players}" if not_enough_blinds?
         error_message = "Only read #{@raise_size_in_each_round} raise sizes, need #{@number_of_rounds}" if not_enough_raise_sizes?

         (0..@number_of_players-1).each do |i|
            if @list_of_blinds[i] > @list_of_player_stacks[i]
               error_message = "Blind for player #{i+1} is greater than stack size"
            end
         end

         (0..@number_of_rounds-1).each do |i|
            if invalid_first_player_position? i
               error_message = "invalid first player #{@first_player_position_in_each_round[i]} on round #{i+1}"
            end
         end

         error_message = "Invalid number of suits: #{@number_of_suits}" if invalid_number_of_suits?
         error_message = "Invalid number of ranks: #{@number_of_ranks}" if invalid_number_of_ranks?
         error_message = "Invalid number of hole cards: #{@number_of_hole_cards}" if invalid_number_of_hole_cards?

         if @number_of_board_cards_in_each_round.length < @number_of_rounds
            error_message = "Only read #{@number_of_board_cards_in_each_round.length} board card numbers, need " +
                    "#{@number_of_rounds}"
         end

         t = @number_of_hole_cards * @number_of_players
         (0..@number_of_rounds-1).each do |i|
            t += @number_of_board_cards_in_each_round[i]
         end

         if t > (@number_of_suits * @number_of_ranks)
            error_message = "Too many hole and board cards for specified deck"
         end
         
      rescue
         error_message = "Undefined instance variable"
      ensure
         raise GameDefinitionParseError, error_message unless error_message.empty?
      end
   end

   def invalid_number_of_rounds?      
      @number_of_rounds.nil? || 0 == @number_of_rounds || @number_of_rounds > MAX_VALUES[:rounds]
   end

   def invalid_number_of_players?      
      @number_of_players < 2 || @number_of_players > MAX_VALUES[:players]
   end

   def invalid_number_of_hole_cards?      
      0 == @number_of_hole_cards || @number_of_hole_cards > MAX_VALUES[:hole_cards]
   end

   def invalid_number_of_ranks?      
      0 == @number_of_ranks || @number_of_ranks > CARD_RANKS.length
   end

   def invalid_number_of_suits?      
      0 == @number_of_suits || @number_of_suits > CARD_SUITS.length
   end

   def invalid_first_player_position?(i)      
      @first_player_position_in_each_round[i] == 0 || @first_player_position_in_each_round[i] > @number_of_players
   end

   def not_enough_raise_sizes?
      @betting_type == 'limit' && @raise_size_in_each_round.length < @number_of_rounds
   end
   
   def not_enough_player_stacks?
      @list_of_player_stacks.length < @number_of_players
   end
   
   def not_enough_blinds?
      @list_of_blinds.length < @number_of_players
   end
end
