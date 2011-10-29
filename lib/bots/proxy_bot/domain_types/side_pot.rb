
# System classes
require 'set'

# Local classes
require File.expand_path('../chip_stack', __FILE__)

# A side pot of chips.
class SidePot < ChipStack
   
   # @return [Set] The set of players involved in this side pot.
   attr_reader :players_involved
   
   # @param [Player] initiating_player The player that initiated this side pot.
   # @param [Integer] initial_amount The initial value of this side pot.
   # @raise (see Stack#initialize)
   def initialize(initiating_player, initial_amount)
      @players_involved = Set.new [initiating_player]
      
      initiating_player.take_from_stack! initial_amount
      
      super initial_amount
   end
   
   # Adds a +number_of_chips+ to this side pot.
   # @param [Player] player The player adding to this side pot.
   def add_to!(player, number_of_chips)
      player.take_from_stack! number_of_chips
      
      @players_involved << player
      
      super number_of_chips
   end
end
