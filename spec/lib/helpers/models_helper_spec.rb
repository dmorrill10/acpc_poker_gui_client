require 'spec_helper'

describe ModelsHelper do
   include ModelsHelper
   
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
end