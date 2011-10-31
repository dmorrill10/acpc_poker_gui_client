require 'spec_helper'

# Local modules
require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe Hand do
   include ApplicationHelpers

   describe '#initialize' do
      it 'understands every possible hand combination' do
         for_every_list_of_two_cards_in_the_deck do |card_1, card_2|
            patient = Hand.new [card_1, card_2]
            
            patient.to_s.should be == "#{card_1}#{card_2}"
         end
      end
   end
end
