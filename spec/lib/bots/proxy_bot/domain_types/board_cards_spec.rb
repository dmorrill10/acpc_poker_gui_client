require 'spec_helper'

# Local modules
require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe BoardCards do
   include ApplicationHelpers

   describe '#initialize' do
      it 'understands every possible board card combination' do
         for_every_card_in_the_deck do |card_1|
            for_every_card_in_the_deck do |card_2|
               for_every_card_in_the_deck do |card_3|
                  for_every_card_in_the_deck do |card_4|
                     for_every_card_in_the_deck do |card_5|
                        BoardCards.new [card_1, card_2, card_3, card_4, card_5]
                     end
                     BoardCards.new [card_1, card_2, card_3, card_4]
                  end
                  BoardCards.new [card_1, card_2, card_3]
               end
               BoardCards.new [card_1, card_2]
            end
            BoardCards.new [card_1]
         end
      end
   end
end
