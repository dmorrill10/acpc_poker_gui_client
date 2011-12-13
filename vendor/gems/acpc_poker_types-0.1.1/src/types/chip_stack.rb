
# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Programmatic representation of a stack of chips.
class ChipStack   
   exceptions :illegal_number_of_chips, :not_enough_chips_in_the_stack
   
   # @return [Integer] The number of chips to be made into a stack (must be a whole number).
   attr_reader :value
   
   # @param [Integer] number_of_chips The number of chips to be made into a stack.
   # @raise (see #sanity_check_number_of_chips)
   def initialize(number_of_chips)
      sanity_check_number_of_chips number_of_chips
      
      @value = number_of_chips
   end
   
   # @todo Mongoid method
   def deserialize(value)
      ChipStack.new value
   end

   # @todo Mongoid method
   def serialize(chip_stack)
      chip_stack.value
   end
   
   # (see #add_to)
   def +(number_of_chips)
      add_to number_of_chips
   end
   
   # Adds a +number_of_chips+ to the stack and returns the sum.
   # @param [Integer] number_of_chips The number of chips to add (must be a whole number).
   # @return [Integer] The sum of the number of chips in this stack and the +number_of_chips+ that were added.
   # @raise (see #sanity_check_number_of_chips)
   def add_to(number_of_chips)
      sanity_check_number_of_chips number_of_chips
      
      @value + number_of_chips
   end
   
   # Adds a +number_of_chips+ to the stack.
   # @param (see #add_to).
   # @raise (see #add_to)
   def add_to!(number_of_chips)
      @value = add_to number_of_chips
   end
   
   def -(number_of_chips)
      take_from number_of_chips
   end
   
   # Takes a +number_of_chips+ from the stack and returns the difference.
   # @param [Integer] number_of_chips The number of chips to be taken
   #  (must be a whole number and must be less than or equal to the number of chips currently in the stack).
   # @raise (see #sanity_check_removal_of_a_number_of_chips)
   def take_from(number_of_chips)
      sanity_check_removal_of_a_number_of_chips number_of_chips
      
      @value - number_of_chips
   end
   
   # Takes a +number_of_chips+ from the stack.
   # @param (see #take_from)
   # @raise (see #take_from)
   def take_from!(number_of_chips)
      @value = take_from number_of_chips
   end
   
   private
   
   # raise IllegalNumberOfChips
   def sanity_check_number_of_chips(number_of_chips)
      raise IllegalNumberOfChips if number_of_chips < 0 or number_of_chips.round != number_of_chips
   end
   
   # raise (see #sanity_check_number_of_chips), NotEnoughChipsInTheStack
   def sanity_check_removal_of_a_number_of_chips(number_of_chips)
      sanity_check_number_of_chips number_of_chips
      
      raise NotEnoughChipsInTheStack if number_of_chips > @value
   end
end
