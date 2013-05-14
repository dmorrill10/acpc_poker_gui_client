require_relative '../../spec_helper'

require 'mongoid_ext/chip_stack'

include AcpcPokerTypes
describe ChipStack do
  it '#mongoize works' do
    x_amount = 14/3.to_r
    ChipStack.new(x_amount).mongoize.should == x_amount
  end
  it '::demongoize works' do
    x_amount = 14/3.to_r
    ChipStack.demongoize(x_amount).should == ChipStack.new(x_amount)
  end
  describe '::mongoize' do
    it 'converts ChipStacks to Rationals' do
      x_amount = 14/3.to_r
      ChipStack.mongoize(ChipStack.new(x_amount)).should == x_amount
    end
    it 'leaves Rationals unmodified' do
      x_amount = 14/3.to_r
      ChipStack.mongoize(x_amount).should == x_amount
    end
  end
  describe '::evolve' do
    it 'converts ChipStacks to Rationals' do
      x_amount = 14/3.to_r
      ChipStack.evolve(ChipStack.new(x_amount)).should == x_amount
    end
    it 'leaves Rationals unmodified' do
      x_amount = 14/3.to_r
      ChipStack.evolve(x_amount).should == x_amount
    end
  end
end