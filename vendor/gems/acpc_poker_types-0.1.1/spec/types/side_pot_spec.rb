
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/side_pot', __FILE__)

describe SidePot do
   before do
      @player1 = mock 'Player'
      @player2 = mock 'Player'
   end
   
   describe 'knows the players that have added to its value' do
      it 'when it is first created' do
         setup_succeeding_test
      end
      it 'when a player makes a bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         
         betting_test patient, players_and_their_contributions
      end
      it 'when a player calls the current bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         
         calling_test patient, players_and_their_contributions
      end
      it 'when a player raises the current bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         (patient, players_and_their_contributions) = betting_test patient, players_and_their_contributions
         
         raising_test patient, players_and_their_contributions
      end
   end
   
   describe 'keeps track of the amount that has been added to its value' do
      it 'when it is first created' do
         (patient,) = setup_succeeding_test
         
         patient.value.should be == @initial_amount_in_side_pot
      end
      it 'when a player makes a bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         
         (patient,) = betting_test patient, players_and_their_contributions
         
         patient.value.should be == 2 * @initial_amount_in_side_pot + @amount_to_bet
      end
      it 'when a player calls the current bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         
         (patient,) = calling_test patient, players_and_their_contributions
         
         patient.value.should be == 2 * @initial_amount_in_side_pot
      end
      it 'when a player raises the current bet' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         (patient, players_and_their_contributions) = betting_test patient, players_and_their_contributions
         
         (patient,) = raising_test patient, players_and_their_contributions
         
         patient.value.should be == @initial_amount_in_side_pot + @amount_to_bet + @amount_to_raise_to
      end
   end
   
   describe '#distribute_chips!' do
      it 'distributes chips properly when only one player involved has not folded' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         (patient,) = betting_test patient, players_and_their_contributions
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         patient.value.should be == chips_to_distribute
         
         @player1.stubs(:has_folded).returns(false)
         @player2.stubs(:has_folded).returns(true)
         @player1.expects(:take_winnings!).once.with(chips_to_distribute)
         
         test_chip_distribution patient, players_and_their_contributions, mock('BoardCards')
      end
      it 'distributes the chips it contains properly to two players that have not folded and have equal hand strength' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         (patient,) = betting_test patient, players_and_their_contributions
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         patient.value.should be == chips_to_distribute
         
         @player1.stubs(:has_folded).returns(false)
         @player2.stubs(:has_folded).returns(false)
         hand = mock 'Hand'
         @player1.stubs(:hole_cards).returns(hand)
         @player2.stubs(:hole_cards).returns(hand)
         
         pile_of_cards = mock 'PileOfCards'
         pile_of_cards.stubs(:to_poker_hand_strength).returns(5)
         PileOfCards.stubs(:new).returns(pile_of_cards)
         
         board_cards = mock 'BoardCards'
         board_cards.stubs(:+).returns(pile_of_cards)
         
         @player1.expects(:take_winnings!).once.with(chips_to_distribute/2)
         @player2.expects(:take_winnings!).once.with(chips_to_distribute/2)
         
         
         test_chip_distribution patient, players_and_their_contributions, board_cards
      end
      it 'distributes the chips it contains properly to two players that have not folded and have unequal hand strength' do
         (patient, players_and_their_contributions) = setup_succeeding_test
         (patient, players_and_their_contributions) = calling_test patient, players_and_their_contributions
         (patient,) = betting_test patient, players_and_their_contributions
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         patient.value.should be == chips_to_distribute
         
         @player1.stubs(:has_folded).returns(false)
         @player2.stubs(:has_folded).returns(false)
         hand1 = mock 'Hand'
         hand2 = mock 'Hand'
         @player1.stubs(:hole_cards).returns(hand1)
         @player2.stubs(:hole_cards).returns(hand2)
         
         pile_of_cards1 = mock 'PileOfCards'
         pile_of_cards1.stubs(:to_poker_hand_strength).returns(9)
         PileOfCards.stubs(:new).with(pile_of_cards1).returns(pile_of_cards1)
         
         pile_of_cards2 = mock 'PileOfCards'
         pile_of_cards2.stubs(:to_poker_hand_strength).returns(10)
         PileOfCards.stubs(:new).with(pile_of_cards2).returns(pile_of_cards2)
         
         board_cards = mock 'BoardCards'
         board_cards.stubs(:+).once.with(hand1).returns(pile_of_cards1)
         board_cards.stubs(:+).once.with(hand2).returns(pile_of_cards2)
         
         @player2.expects(:take_winnings!).once.with(chips_to_distribute)
         
         test_chip_distribution patient, players_and_their_contributions, board_cards
      end
      it 'raises an exception if there are no chips to distribute' do
         initial_amount_in_side_pot = 0
         @player1.expects(:take_from_chip_stack!).once.with(initial_amount_in_side_pot)
      
         patient = SidePot.new @player1, initial_amount_in_side_pot
      
         players_and_their_contributions = {@player1 => initial_amount_in_side_pot}
      
         patient.players_involved_and_their_amounts_contributed.should eq(players_and_their_contributions)
         
         expect{patient.distribute_chips! mock('BoardCards')}.to raise_exception(SidePot::NoChipsToDistribute)
      end
      it 'raises an exception if there are no players to take chips' do
         pending 'multiplayer support'
         #expect{patient.distribute_chips!}.to raise_exception(SidePot::NoPlayersToTakeChips)
      end
   end
   
   def setup_succeeding_test
      @initial_amount_in_side_pot = 10
      @player1.expects(:take_from_chip_stack!).once.with(@initial_amount_in_side_pot)
      
      patient = SidePot.new @player1, @initial_amount_in_side_pot
      
      players_and_their_contributions = {@player1 => @initial_amount_in_side_pot}
      
      patient.players_involved_and_their_amounts_contributed.should be == players_and_their_contributions
      
      [patient, players_and_their_contributions]
   end
   
   def calling_test(patient, players_and_their_contributions)
      @player2.expects(:take_from_chip_stack!).once.with(@initial_amount_in_side_pot)
      players_and_their_contributions[@player2] = @initial_amount_in_side_pot
      
      patient.take_call! @player2
         
      patient.players_involved_and_their_amounts_contributed.should be == players_and_their_contributions
      
      [patient, players_and_their_contributions]
   end
   
   def betting_test(patient, players_and_their_contributions)
      @amount_to_bet = 34
      @player1.expects(:take_from_chip_stack!).once.with(@amount_to_bet)
      players_and_their_contributions[@player1] += @amount_to_bet
      
      patient.take_bet! @player1, @amount_to_bet
      
      patient.players_involved_and_their_amounts_contributed.should be == players_and_their_contributions
      
      [patient, players_and_their_contributions]
   end
   
   def raising_test(patient, players_and_their_contributions)
      @amount_to_raise_to = 111
      @total_amount = @amount_to_raise_to
      @player2.expects(:take_from_chip_stack!).once.with(@amount_to_bet)
      @player2.expects(:take_from_chip_stack!).once.with(@amount_to_raise_to - (@amount_to_bet + @initial_amount_in_side_pot))
      
      players_and_their_contributions[@player2] = @total_amount
      
      patient.take_raise! @player2, @amount_to_raise_to
      
      patient.players_involved_and_their_amounts_contributed.should be == players_and_their_contributions
      
      [patient, players_and_their_contributions]
   end
   
   def test_chip_distribution(patient, players_and_their_contributions, board_cards)
      players_and_their_contributions = {}
         
      patient.distribute_chips! board_cards
         
      patient.value.should be == 0
      patient.players_involved_and_their_amounts_contributed.should be == players_and_their_contributions
      
      [patient, players_and_their_contributions]
   end
end