require 'spec_helper'

# System classes
require 'set'

# Local modules
require File.expand_path('../../../../../../lib/application_defs', __FILE__)
require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe Hand do
   include ApplicationDefs
   include ApplicationHelpers

   describe '#initialize' do
      it 'parses every possible hand combination' do
         for_every_list_of_two_cards_in_the_deck do |card_1, card_2|
            Hand.new [card_1, card_2]
         end
      end
   end
   #describe 
end
