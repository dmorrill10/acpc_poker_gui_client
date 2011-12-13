
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/chip_stack', __FILE__)

describe ChipStack do
   describe '#initialization' do
      describe 'raises an exception if the number of chips to be made into a stack' do
         it 'is a decimal' do
            expect{ChipStack.new(1.1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is negative' do
            expect{ChipStack.new(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
   end
   describe '#value' do
      it 'reports the number of chips the stack contains' do
         number_of_chips = 100
         patient = ChipStack.new number_of_chips
         
         patient.value.should be number_of_chips
      end
   end
   describe '#add_to' do
      describe 'raises an exception if the number of chips to be made into a stack' do
         it 'is a decimal' do
            patient = ChipStack.new 100
            expect{patient.add_to(1.1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is negative' do
            patient = ChipStack.new 100
            expect{patient.add_to(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
      it 'adds a number of chips to the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_added = 50
         number_of_chips = initial_number_of_chips + amount_added
         
         patient.add_to(amount_added).should eq(number_of_chips)
      end
   end
   describe '#add_to!' do
      describe 'raises an exception if the number of chips to be added' do
         it 'is a decimal' do
            patient = ChipStack.new 100
            expect{patient.add_to!(1.1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is negative' do
            patient = ChipStack.new 100
            expect{patient.add_to!(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
      it 'adds a number of chips to the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_added = 50
         number_of_chips = initial_number_of_chips + amount_added
         
         patient.add_to!(amount_added)
         
         patient.value.should eq(number_of_chips)
      end
   end
   describe '#take_from' do
      describe 'raises an exception if the number of chips to be taken' do
         it 'is a decimal' do
            patient = ChipStack.new 100
            expect{patient.take_from(1.1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is negative' do
            patient = ChipStack.new 100
            expect{patient.take_from(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is greater than the number of chips in the stack' do
            patient = ChipStack.new 100
            expect{patient.take_from(101)}.to raise_exception(ChipStack::NotEnoughChipsInTheStack)
         end
      end
      it 'takes a number of chips from the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_taken = 50
         number_of_chips = initial_number_of_chips - amount_taken
         
         patient.take_from(amount_taken).should eq(number_of_chips)
      end
   end
   describe '#take_from!' do
      describe 'raises an exception if the number of chips to be taken' do
         it 'is a decimal' do
            patient = ChipStack.new 100
            expect{patient.take_from!(1.1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is negative' do
            patient = ChipStack.new 100
            expect{patient.take_from!(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
         it 'is greater than the number of chips in the stack' do
            patient = ChipStack.new 100
            expect{patient.take_from!(101)}.to raise_exception(ChipStack::NotEnoughChipsInTheStack)
         end
      end
      it 'takes a number of chips from the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_taken = 50
         number_of_chips = initial_number_of_chips - amount_taken
         
         patient.take_from!(amount_taken)
         patient.value.should eq(number_of_chips)
      end
   end
end
