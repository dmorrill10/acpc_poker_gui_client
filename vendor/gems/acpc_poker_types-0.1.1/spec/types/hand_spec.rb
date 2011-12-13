
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local modules
require File.expand_path('../../../src/acpc_poker_types_defs', __FILE__)
require File.expand_path('../../../src/helpers/acpc_poker_types_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/hand', __FILE__)

describe Hand do
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   

   describe '#initialize' do
      it 'understands every posspaible card combination' do
         for_every_list_of_two_cards_in_the_deck do |card_1, card_2|
            patient = Hand.new [card_1, card_2]
            
            patient.to_s.should be == "#{card_1}#{card_2}"
         end
      end
      it 'understands every possible string hand' do
         LIST_OF_HOLE_CARD_HANDS.each do |string_hand|
            patient = Hand.draw_cards string_hand
            
            patient.to_s.should be == string_hand
         end
      end
   end
end
