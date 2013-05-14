require_relative '../../spec_helper'

require 'mongoid_ext/player'

include AcpcPokerTypes
describe Player do
  it '#mongoize works after assigning a hand and taking an action' do
    x_name = 'p1'
    x_seat = 0
    x_chip_stack = ChipStack.new(100)
    x_hand = Hand.new(Card.cards('AhKs'))
    x_action = 'b100'
    Player.new(x_name, x_seat, x_chip_stack)
      .start_new_hand!
      .assign_cards!(x_hand)
      .take_action!(PokerAction.new(x_action))
      .mongoize
      .should == {
        name: x_name,
        seat: x_seat,
        chip_stack: x_chip_stack.mongoize,
        chip_contributions: [0.to_r],
        chip_balance: 0.to_r,
        hole_cards: x_hand.mongoize,
        actions_taken_this_hand: [[x_action]]
      }
  end
  it '::demongoize works' do
    x_name = 'p1'
    x_seat = 0
    x_chip_stack = ChipStack.new(100)
    x_hand = Hand.new(Card.cards('AhKs'))
    x_action = PokerAction.new('r100')

    Player.demongoize(
      {
        name: x_name,
        seat: x_seat,
        chip_stack: x_chip_stack.mongoize,
        chip_contributions: [0.to_r],
        chip_balance: 0.to_r,
        hole_cards: x_hand.mongoize,
        actions_taken_this_hand: [[x_action.to_acpc]]
      }
    ).should == Player.new(x_name, x_seat, x_chip_stack)
      .start_new_hand!
      .assign_cards!(x_hand)
      .take_action!(x_action)


  end
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