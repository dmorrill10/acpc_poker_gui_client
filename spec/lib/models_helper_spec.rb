require 'spec_helper'

describe ModelsHelper do
   it 'properly flattens an array to a single element if that is all the array contains and leaves it unchanged otherwise' do
      one_element_array = ['a']
      two_element_array = ['a', 'b']
      
      flatten_if_single_element_array(one_element_array).should be one_element_array[0]
      flatten_if_single_element_array(two_element_array).should be two_element_array
   end
   
   it 'properly detects a comment' do
      hash_comment = '# hash comment'
      semicolon_comment = '; semicolon comment'
      empty_line = ''
      not_a_comment = 'not a comment'
      
      line_is_comment_or_empty?(hash_comment).should be == true
      line_is_comment_or_empty?(semicolon_comment).should be == true
      line_is_comment_or_empty?(empty_line).should be == true
      line_is_comment_or_empty?(not_a_comment).should be == false
   end
   
   it 'converts the string representation of every card into its proper numeric ACPC representation' do
      CARD_RANKS.values.each do |string_rank|
         CARD_SUITS.values.each do |string_suit|
            string_card = string_rank + string_suit
            integer_rank = CARD_RANK_NUMBERS[string_rank]
            integer_suit = CARD_SUIT_NUMBERS[string_suit]
            integer_card = integer_rank * CARD_SUITS.length + integer_suit
            
            make_acpc_card(integer_rank, integer_suit).should be == integer_card
            to_acpc_card_from_card_string(string_card).should be == integer_card
         end
      end
   end
   
   
   
   #before(:each) do
   #   @name = 'p1'
   #   @seat = '1'
   #   @position_relative_to_dealer = '0'
   #   @position_relative_to_user = '1'
   #   @stack = 2000
   #   
   #   @patient = Player.new @name, @seat, @position_relative_to_dealer, @position_relative_to_user, @stack
   #end
   #
   #it 'reports its attributes correctly' do
   #   @patient.name.should be == @name
   #   @patient.seat.should be == @seat
   #   @patient.position_relative_to_dealer.should be == @position_relative_to_dealer
   #   @patient.position_relative_to_user.should be == @position_relative_to_user
   #   @patient.stack.should be == @stack
   #end
   #
   #it 'reports it is not active if it is all-in' do
   #   @patient.is_active?.should be == true
   #   @patient.is_all_in = true
   #   @patient.is_active?.should be == false
   #end
   #
   #it 'reports it is not active if it has folded' do
   #   @patient.is_active?.should be == true
   #   @patient.has_folded = true
   #   @patient.is_active?.should be == false
   #end
   #
   #it 'properly changes its state when it calls the current wager that it faces' do
   #   @patient.number_of_chips_in_the_pot.should be == 0
   #   @patient.current_wager_faced.should be == 0
   #   @patient.chip_balance.should be == 0
   #   
   #   wager_amount = 20
   #   @patient.current_wager_faced = wager_amount
   #   @patient.call_current_wager!
   #   
   #   @patient.stack.should be == @stack - wager_amount
   #   @patient.number_of_chips_in_the_pot.should be == wager_amount
   #   @patient.current_wager_faced.should be == 0
   #   @patient.chip_balance.should be == -wager_amount
   #end
   #
   #it 'properly changes its state when it wins the current pot' do
   #   @patient.current_wager_faced.should be == 0
   #   @patient.chip_balance.should be == 0
   #   
   #   pot_size = 22
   #   @patient.take_winnings! pot_size
   #   
   #   @patient.number_of_chips_in_the_pot.should be == 0
   #   @patient.current_wager_faced.should be == 0
   #   @patient.stack.should be == @stack + pot_size
   #   @patient.chip_balance.should be == pot_size
   #end
end