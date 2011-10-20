require 'spec_helper'

describe Player do
   class FakeStack
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
      @stack = FakeStack.new 2000
      
      @patient = Player.new @name, @seat, @position_relative_to_dealer, @position_relative_to_user, @stack
   end
   
   it 'reports its attributes correctly' do
      @patient.name.should be == @name
      @patient.seat.should be == @seat
      @patient.position_relative_to_dealer.should be == @position_relative_to_dealer
      @patient.position_relative_to_user.should be == @position_relative_to_user
      @patient.stack.should be == @stack
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
   
   it 'properly changes its state when it calls the current wager that it faces' do
      @patient.number_of_chips_in_the_pot.should be == 0
      @patient.current_wager_faced.should be == 0
      @patient.chip_balance.should be == 0
      
      wager_amount = 20
      @patient.current_wager_faced = wager_amount
      @patient.call_current_wager!
      
      @patient.stack.should be == @stack - wager_amount
      @patient.number_of_chips_in_the_pot.should be == wager_amount
      @patient.current_wager_faced.should be == 0
      @patient.chip_balance.should be == -wager_amount
   end
   
   it 'properly changes its state when it wins the current pot' do
      @patient.current_wager_faced.should be == 0
      @patient.chip_balance.should be == 0
      
      pot_size = 22
      @patient.take_winnings! pot_size
      
      @patient.number_of_chips_in_the_pot.should be == 0
      @patient.current_wager_faced.should be == 0
      @patient.stack.should be == @stack + pot_size
      @patient.chip_balance.should be == pot_size
   end
   
   it 'properly converts its hole cards to their numeric ACPC representation' do
      all_ranks = CARD_RANKS.values.join ''
      all_suits = CARD_SUITS.values.join ''
      
      LIST_OF_HOLE_CARD_HANDS.each do |string_hole_card_hand|
         integer_hole_card_hand = []
         
         string_hole_card_hand.scan(/[#{all_ranks}][#{all_suits}]/).each do |string_card|
            integer_hole_card_hand << to_acpc_card_from_card_string(string_card)
         end
         
         log "integer_hole_card_hand: #{integer_hole_card_hand}"
         
         @patient.hole_cards = string_hole_card_hand
         @patient.to_acpc_cards.should be == integer_hole_card_hand
      end
   end
end