
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/player', __FILE__)

describe Player do
   class FakeChipStack
      attr_reader :value
      def initialize(number)
         @value = number
      end
      def +(number)
         add_to number
      end
      def -(number)
         take_from number
      end
      def add_to(number)
         @value + number
      end
      def add_to!(number)
         @value = add_to number
      end
      def take_from(number)
         @value - number
      end
      def take_from!(number)
         @value = take_from number
      end
   end
   
   before(:each) do
      @name = 'p1'
      @seat = '1'
      @position_relative_to_dealer = '0'
      @position_relative_to_user = '1'
      @chip_stack = FakeChipStack.new 2000
      
      @patient = Player.new @name, @seat, @position_relative_to_dealer, @position_relative_to_user, @chip_stack.dup
   end
   
   it 'reports its attributes correctly' do
      @patient.name.should be == @name
      @patient.seat.should be == @seat
      @patient.position_relative_to_dealer.should be == @position_relative_to_dealer
      @patient.position_relative_to_user.should be == @position_relative_to_user
      @patient.chip_stack.value.should be == @chip_stack.value
   end
   it 'reports it is not active if it is all-in' do
      @patient.is_active?.should be == true
      @patient.is_all_in = true
      @patient.is_active?.should be == false
   end
   it 'reports it is not active if it has folded' do
      @patient.is_active?.should be == true
      @patient.has_folded = true
      @patient.is_active?.should be == false
   end
   it 'properly changes its state when it contributes chips to a side-pot' do
      @patient.chip_balance.should be == 0
      @patient.chip_stack.value.should be == @chip_stack.value
      
      @patient.take_from_chip_stack! @chip_stack.value
      
      @patient.chip_stack.value.should be == 0
      @patient.chip_balance.should be == -@chip_stack.value
   end
   it 'properly changes its state when it wins chips' do
      @patient.chip_balance.should be == 0
      
      pot_size = 22
      @patient.take_winnings! pot_size
      
      @patient.chip_stack.value.should be == @chip_stack + pot_size
      @patient.chip_balance.should be == pot_size
   end
end