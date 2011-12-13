
# Provides +Array+ with custom convenience methods.
class Array
   
   # @param [Integer] index_of_first_element The index of the first element in the returned list.
   # @return [Array] All elements of the array except the elements before +index_of_first_element+.
   def rest(index_of_first_element=1)
      return [] if empty?
      slice(index_of_first_element..-1)
   end
end
