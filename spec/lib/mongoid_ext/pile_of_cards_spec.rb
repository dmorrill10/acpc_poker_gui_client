require_relative '../../spec_helper'

require 'acpc_poker_types/pile_of_cards'
require 'mongoid_ext/card'

include AcpcPokerTypes
describe PileOfCards do
  it '#mongoize works' do
    PileOfCards.new(pile_with_cards).mongoize.should == pile_with_strings
    PileOfCards.new(pile_with_cards).mongoize.each do |card|
      card.should be_kind_of(String)
    end
  end
  it '::demongoize works' do
    PileOfCards.demongoize(pile_with_cards).should == pile_with_cards
  end
  describe '::mongoize' do
    it 'converts piles of cards to arrays of strings' do
      PileOfCards.mongoize(pile_with_cards).should == pile_with_strings
    end
    it 'leaves arrays of strings unmodified' do
      x_pile = ['Ah', 'Ks']
      PileOfCards.mongoize(x_pile).should == x_pile
    end
  end
  describe '::evolve' do
    it 'converts piles of cards to arrays of strings' do
      PileOfCards.evolve(pile_with_cards).should == pile_with_strings
    end
    it 'leaves arrays of strings unmodified' do
      PileOfCards.evolve(pile_with_strings).should == pile_with_strings
    end
  end

  def pile_with_cards
    Card.cards('AhKs')
  end
  def pile_with_strings
    (pile_with_cards.map { |card| card.mongoize })
  end
end