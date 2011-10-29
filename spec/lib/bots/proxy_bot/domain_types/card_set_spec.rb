require 'spec_helper'

# Local modules
require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe CardSet do
   include ApplicationHelpers

   describe '#to_texas_holdem_strength' do
      it "can calculate the Texas hold'em poker hand strength for itself for a seven card set" do
         pending
         for_every_list_of_two_cards_in_the_deck do |card_1, card_2|
            CardSet.new [card_1, card_2]
         end
      end
   end
end
