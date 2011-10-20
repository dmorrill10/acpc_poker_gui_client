require 'spec_helper'

describe SidePot do
   before do
      @player1 = mock 'Player'
      @player2 = mock 'Player'
   end
   
   describe 'knows the players that have added to its value' do
      it 'when it is first created' do
         initial_amount_in_side_pot = 10
         @player1.expects(:take_from_stack!).once.with(initial_amount_in_side_pot)
      
         patient = SidePot.new @player1, initial_amount_in_side_pot
         
         patient.players_involved.should eq([@player1])
      end
      it 'when a player adds to its value' do
         initial_amount_in_side_pot = 10
         @player1.expects(:take_from_stack!).once.with(initial_amount_in_side_pot)
         
         patient = SidePot.new @player1, initial_amount_in_side_pot
         
         amount_to_add = 22
         @player2.expects(:take_from_stack!).once.with(amount_to_add)
         
         patient.add_to! @player2, amount_to_add
         
         patient.players_involved.should eq([@player1, @player2])
      end
   end
   
   describe '#distribute_chips' do
      it 'distributes the chips it contains properly to all active players involved' do
         pending 'waiting for Cards, Hands, and BoardCards'
      end
   end
end