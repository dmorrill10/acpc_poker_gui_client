require 'spec_helper'

# System classes
require 'set'

describe SidePot do
   before do
      @player1 = mock 'Player'
      @player2 = mock 'Player'
   end
   
   describe 'knows the players that have added to its value' do
      it 'when it is first created' do
         patient = setup_succeeding_test
      end
      it 'when a player makes a bet' do
         patient = setup_succeeding_test
         patient = betting_test
      end
      it 'when a player calls the current bet' do
         patient = setup_succeeding_test
         patient = betting_test
         
         @player1.expects(:take_from_stack!).once.with(@amount_to_bet)
         
         patient.take_call! @player1
      end
      it 'when a player raises the current bet' do
         pending
      end
   end
   
   describe '#distribute_chips!' do
      it 'distributes chips properly when only one player involved has not folded' do
         pending
      end
      it 'distributes the chips it contains properly to all non-folded players involved' do
         # The side pot looks at all the board cards and the cards of all non-folded players involved
         # and decides which players deserve its chips
         
         
         
         pending 'waiting for Cards, Hands, and BoardCards'
      end
   end
   
   def setup_succeeding_test
      @initial_amount_in_side_pot = 10
      @player1.expects(:take_from_stack!).once.with(initial_amount_in_side_pot)
      
      patient = SidePot.new @player1, initial_amount_in_side_pot
         
      patient.players_involved.should eq([@player1].to_set)
      
      patient
   end
   
   def betting_test
      @amount_to_bet = 22
      @player2.expects(:take_from_stack!).once.with(@amount_to_bet + @initial_amount_in_side_pot)
         
      patient.take_bet! @player2, @amount_to_bet
      
      patient
   end
end