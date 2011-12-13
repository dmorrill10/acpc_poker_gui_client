
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Local classes
require File.expand_path('../../types/card', __FILE__)

# Assortment of constant definitions and methods for generating default values.
module AcpcPokerTypesHelper
   # @param [Integer] number_of_players The number of players that require stacks.
   # @return [Array] The default list of initial stacks for every player.
   def default_list_of_player_stacks(number_of_players)
      list_of_player_stacks = []
      number_of_players.times do
         # @todo The dealer uses AcpcPokerTypesDefs::INT32_MAX but it would look nicer for no limit to use 500. Not sure exactly what should be done here.
         list_of_player_stacks << 500
      end
      list_of_player_stacks
   end
   
   # @yield [Card, Card] Iterate through every permutation of cards in the deck.
   # @yieldparam (see #for_every_rank_and_suit_in_the_deck)
   def for_every_list_of_two_cards_in_the_deck
      for_every_rank_and_suit_in_the_deck do |rank_1, suit_1|
         for_every_rank_and_suit_in_the_deck do |rank_2, suit_2|
            card_1 = Card.new rank_1, suit_1
            card_2 = Card.new rank_2, suit_2
            
            yield card_1, card_2
         end
      end
   end
   
   # @yield [Card] Iterate through every recognized card.
   # @yieldparam (see #for_every_rank_and_suit_in_the_deck)
   def for_every_card_in_the_deck
      for_every_rank_and_suit_in_the_deck do |rank, suit|
         yield Card.new rank, suit
      end
   end
   
   # @yield [Symbol, Symbol] Iterate through every combination of ranks and suits in the deck.
   # @yieldparam (see #for_every_suit_in_the_deck)
   # @yieldparam (see #for_every_rank_in_the_deck)
   def for_every_rank_and_suit_in_the_deck
      for_every_rank_in_the_deck do |rank|
         for_every_suit_in_the_deck do |suit|   
            yield rank, suit
         end
      end
   end
   
   # @yield [Symbol] Iterate through every recognized rank.
   # @yieldparam [Symbol] rank The rank of the card.
   def for_every_rank_in_the_deck
      AcpcPokerTypesDefs::CARD_RANKS.keys.each { |rank| yield rank }
   end
   
   # @yield [Symbol] Iterate through every recognized suit.
   # @yieldparam [Symbol] suit The suit of the card.
   def for_every_suit_in_the_deck
      AcpcPokerTypesDefs::CARD_SUITS.keys.each { |suit| yield suit }
   end
   
   # Flatten a given array into a single element if there is only one element in the array.
   # That is, if the given array is a single element array, it returns that element,
   # otherwise it returns the array.
   #
   # @param [Array] array The array to flatten into a single element.
   # @return +array+ if +array+ has more than one element, the single element in +array+ otherwise.
   def flatten_if_single_element_array(array)
      if 1 == array.length then array[0] else array end
   end

   # Loops over every line in the file corresponding to the given file name.
   #
   # @param [String] file_name The name of the file to loop through.
   # @yield Block to operate on +line+.
   # @yieldparam [String] line A line from the file corresponding to +file_name+.
   # @raise [Errno::ENOENT] Unable to open or read +file_name+ error.
   def for_every_line_in_file(file_name)
      begin
         file = File.new file_name, "r"
      rescue
         raise "Unable to open #{file_name}"
      else         
         begin
            while line = file.gets do
               line.chomp!
               
               yield line
            end
         rescue Errno::ENOENT => e
            raise e, "Unable to read #{file_name}: #{e.message}"
         end
      ensure
         file.close if file
      end
   end

   # Checks if the given line is a comment beginning with '#' or ';', or empty.
   #
   # @param [String] line
   # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
   def line_is_comment_or_empty?(line)
      return true unless line
      !line.match(/^\s*[#;]/).nil? or line.empty?
   end
end
