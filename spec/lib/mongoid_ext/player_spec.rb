require_relative '../../spec_helper'

require 'lib/mongoid_ext/player'

include AcpcPokerTypes
describe Player do
  it '#mongoize works after assigning a hand and taking an action' do
    x_name = 'p1'
    x_seat = 0
    x_chip_stack = ChipStack.new(100)
    x_hand = Hand.new(['Ah', 'Ks'])
    Player.new(x_name, x_seat, x_chip_stack)
      .start_new_hand!
      .assign_cards!(x_hand)
      .take_action!(PokerAction.new('r100'))
      .mongoize
      .should == {
        name: x_name,
        seat: x_seat,
        chip_stack: x_chip_stack.mongoize
        hole_cards: x_hand.mongoize
      }
# @todo Finish test
    .mongoize.should == x_pile
  end
  # it '::demongoize works' do
  #   x_pile = ['Ah', 'Ks']
  #   Player.demongoize(x_pile).should == Player.new(x_pile)
  # end
  # describe '::mongoize' do
  #   it 'converts piles of cards to Arrays' do
  #     x_pile = ['Ah', 'Ks']
  #     Player.mongoize(Player.new(x_pile)).should == x_pile
  #   end
  #   it 'leaves Arrays unmodified' do
  #     x_pile = ['Ah', 'Ks']
  #     Player.mongoize(x_pile).should == x_pile
  #   end
  # end
  # describe '::evolve' do
  #   it 'converts piles of cards to Arrays' do
  #     x_pile = ['Ah', 'Ks']
  #     Player.evolve(Player.new(x_pile)).should == x_pile
  #   end
  #   it 'leaves Arrays unmodified' do
  #     x_pile = ['Ah', 'Ks']
  #     Player.evolve(x_pile).should == x_pile
  #   end
  end
end