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
end