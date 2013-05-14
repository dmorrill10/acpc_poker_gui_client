require_relative '../../spec_helper'

require 'acpc_poker_types/pile_of_cards'
require_relative '../../../lib/mongoid_ext/card'

include AcpcPokerTypes
describe PileOfCards do
  it '#mongoize works' do
    x_pile = Card.cards('AhKs')
    PileOfCards.new(x_pile).mongoize.should == (x_pile.map { |card| card.mongoize })
    PileOfCards.new(x_pile).mongoize.each do |card|
      card.should be_kind_of(String)
    end
  end
  # @todo Fix the rest
  it '::demongoize works' do
    x_pile = ['Ah', 'Ks']
    PileOfCards.demongoize(x_pile).should == PileOfCards.new(x_pile)
  end
  describe '::mongoize' do
    it 'converts piles of cards to Arrays' do
      x_pile = ['Ah', 'Ks']
      PileOfCards.mongoize(PileOfCards.new(x_pile)).should == x_pile
    end
    it 'leaves Arrays unmodified' do
      x_pile = ['Ah', 'Ks']
      PileOfCards.mongoize(x_pile).should == x_pile
    end
  end
  describe '::evolve' do
    it 'converts piles of cards to Arrays' do
      x_pile = ['Ah', 'Ks']
      PileOfCards.evolve(PileOfCards.new(x_pile)).should == x_pile
    end
    it 'leaves Arrays unmodified' do
      x_pile = ['Ah', 'Ks']
      PileOfCards.evolve(x_pile).should == x_pile
    end
  end
end