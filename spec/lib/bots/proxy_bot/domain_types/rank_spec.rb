require 'spec_helper'

require File.expand_path('../../../../../../lib/application_defs', __FILE__)
require File.expand_path('../../../../../../lib/helpers/application_helpers', __FILE__)

describe Rank do
   include ApplicationDefs
   include ApplicationHelpers
   
   describe '#initialization' do
      it 'raises an exception if the given rank is invalid' do
         expect{Rank.new(:not_a_rank)}.to raise_exception(Rank::NotARecognizedRank)
      end
      it 'correctly understands all ranks currently recognized' do
         for_every_rank_in_the_deck { |rank| Rank.new(rank) }
      end
   end
   describe '#to_i' do
      it 'converts every rank into its proper and numeric ACPC representation' do
         for_every_rank_in_the_deck do |rank|
            patient = Rank.new rank
            
            string_rank = CARD_RANKS[rank]
            integer_rank = CARD_RANK_NUMBERS[string_rank]
            
            patient.to_i.should eq(integer_rank)
         end
      end
   end
   describe '#to_s' do
      it 'converts every rank into its proper string representation' do
         for_every_rank_in_the_deck do |rank|
            patient = Rank.new rank
            
            string_rank = CARD_RANKS[rank]
            
            patient.to_s.should eq(string_rank)
         end
      end
   end
end
