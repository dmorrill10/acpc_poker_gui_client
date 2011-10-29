
# Local modules
require File.expand_path('../../application_defs', __FILE__)

# Local classes
require File.expand_path('../../bots/proxy_bot/domain_types/card', __FILE__)

# Assortment of constant definitions and methods for generating default values.
module ApplicationHelpers  
   # @return [Array] The default first player position in each round.
   def default_first_player_position_in_each_round
      first_player_position_in_each_round = []
      ApplicationDefs::MAX_VALUES[:rounds].times do
         first_player_position_in_each_round << 1
      end
      first_player_position_in_each_round
   end
   
   # @return [Array] The default maximum raise in each round.
   def default_max_raise_in_each_round
      max_raise_in_each_round = []
      ApplicationDefs::MAX_VALUES[:rounds].times do
         max_raise_in_each_round << ApplicationDefs::UINT8_MAX
      end
      max_raise_in_each_round
   end
   
   # @param [Integer] number_of_players The number of players that require stacks.
   # @return [Array] The default list of initial stacks for every player.
   def default_list_of_player_stacks(number_of_players)
      list_of_player_stacks = []
      number_of_players.times do
         list_of_player_stacks << ApplicationDefs::INT32_MAX
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
      ApplicationDefs::CARD_RANKS.keys.each { |rank| yield rank }
   end
   
   # @yield [Symbol] Iterate through every recognized suit.
   # @yieldparam [Symbol] suit The suit of the card.
   def for_every_suit_in_the_deck
      ApplicationDefs::CARD_SUITS.keys.each { |suit| yield suit }
   end
   
   # Prints a given string prepended by the current class name if +DEBUG+ is true.
   # @param [#to_s] object The object to print.
   def log(object)
      puts "#{self.class}: #{object}" if DEBUG
   end
end
