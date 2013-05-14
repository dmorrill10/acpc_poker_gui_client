require_relative '../../spec_helper'

require 'mongoid_ext/card'

include AcpcPokerTypes
describe Card do
  it '#mongoize works' do
    x_card_string = 'Ah'
    Card.from_acpc(x_card_string).mongoize.should == x_card_string
  end
  it '::demongoize works' do
    x_card_string = 'Ah'
    Card.demongoize(x_card_string).should == Card.from_acpc(x_card_string)
  end
  describe '::mongoize' do
    it 'converts Cards to string' do
      x_card_string = 'Ah'
      Card.mongoize(Card.from_acpc(x_card_string)).should == x_card_string
    end
    it 'leaves strings unmodified' do
      x_card_string = 'Ah'
      Card.mongoize(x_card_string).should == x_card_string
    end
  end
  describe '::evolve' do
    it 'converts Cards to strings' do
      x_card_string = 'Ah'
      Card.evolve(Card.from_acpc(x_card_string)).should == x_card_string
    end
    it 'leaves strings unmodified' do
      x_card_string = 'Ah'
      Card.evolve(x_card_string).should == x_card_string
    end
  end
end