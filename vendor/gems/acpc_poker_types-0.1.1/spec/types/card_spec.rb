
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local modules
require File.expand_path('../../../src/acpc_poker_types_defs', __FILE__)
require File.expand_path('../../../src/helpers/acpc_poker_types_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/card', __FILE__)

describe Card do
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   
   describe '#new' do
      describe 'raises an exception if' do
         it 'the given suit is invalid' do
            expect{Card.new(:ace, :not_a_suit)}.to raise_exception(Suit::NotARecognizedSuit)
         end
         it 'the given rank is invalid' do
            expect{Card.new(:not_a_rank, :spades)}.to raise_exception(Rank::NotARecognizedRank)
         end
      end
      it 'correctly understands all suits and ranks currently recognized' do
         for_every_rank_and_suit_in_the_deck { |rank, suit| Card.new(rank, suit) }
      end
      it 'correctly understands all suits and ranks currently recognized in string form' do
         for_every_rank_and_suit_in_the_deck { |rank, suit| Card.new(CARD_RANKS[rank] + CARD_SUITS[suit]) }
      end
   end
   describe '#to_i' do
      it 'converts every card into its proper integer ACPC representation' do
         for_every_rank_and_suit_in_the_deck do |rank, suit|
            patient = Card.new rank, suit
            
            string_rank = CARD_RANKS[rank]
            string_suit = CARD_SUITS[suit]
               
            integer_rank = CARD_RANK_NUMBERS[string_rank]
            integer_suit = CARD_SUIT_NUMBERS[string_suit]
            integer_card = integer_rank * CARD_SUITS.length + integer_suit
            
            patient.to_i.should eq(integer_card)
         end
      end
   end
   describe '#to_s' do
      it 'converts every card into its proper string representation' do
         for_every_rank_and_suit_in_the_deck do |rank, suit|
            patient = Card.new rank, suit
            
            string_rank = CARD_RANKS[rank]
            string_suit = CARD_SUITS[suit]
            string_card = string_rank + string_suit
               
            patient.to_s.should eq(string_card)
         end
      end
   end
   
   # @param [Integer] integer_rank The integer ACPC representation of the card's rank.
   # @param [Integer] integer_suit The integer ACPC representation of the card's suit.
   # @return [Integer] The integer ACPC representation of the card.
   def make_acpc_card(integer_rank, integer_suit)
      integer_rank * CARD_SUITS.length + integer_suit
   end
   
   # @param [String] string_card A card represented by a string of the form
   #  '<rank><suit>'
   # @return [Integer] The numeric ACPC representation of the card.
   def to_acpc_card_from_card_string(string_card)
      string_rank = string_card[0]
      string_suit = string_card[1]
      
      integer_rank = CARD_RANK_NUMBERS[string_rank]
      integer_suit = CARD_SUIT_NUMBERS[string_suit]
            
      make_acpc_card(integer_rank, integer_suit)
   end
end
