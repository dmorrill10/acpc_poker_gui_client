require 'spec_helper'

require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe Card do
   include ApplicationHelpers
   
   describe '#initialization' do
      describe 'raises an exception if' do
         it 'the given suit is invalid' do
            expect{Card.new(:not_a_suit, :Ace)}.to raise_exception(Card::NotARecognizedSuit)
         end
         it 'the given rank is invalid' do
            expect{Card.new(:spades, :not_a_rank)}.to raise_exception(Card::NotARecognizedRank)
         end
      end
      it 'correctly understands all suits and ranks currently recognized' do
         for_each_card_in_the_deck { |suit, rank| Card.new(suit, rank) }
      end
   end
   describe '#to_acpc' do
      it 'converts every card into its proper numeric ACPC representation' do
         for_each_card_in_the_deck do |suit, rank|
            patient = Card.new suit, rank
            
            string_rank = CARD_RANKS[:rank]
            string_suit = CARD_SUITS[:suit]
               
            integer_rank = CARD_RANK_NUMBERS[string_rank]
            integer_suit = CARD_SUIT_NUMBERS[string_suit]
            integer_card = integer_rank * CARD_SUITS.length + integer_suit
            
            patient.to_acpc.should eq(integer_card)
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
