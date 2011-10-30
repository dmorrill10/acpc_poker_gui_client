
# Local classes
require File.expand_path('../chip_stack', __FILE__)

# Class to model a player.  This is a data model that contains minimal logic.
class Player   
   # @return [String] The name of this player.
   attr_reader :name
   
   # @return [Integer] This player's seat.  This is a 1 indexed
   #     number that represents the order that the player joined the dealer.
   attr_reader :seat
   
   # @return [Integer] This player's position relative to the dealer,
   #     0 indexed, modulo the number of players in the game.
   # @example (see MatchstateString#position_relative_to_dealer)
   attr_reader :position_relative_to_dealer
   
   # @return [Integer] This player's position relative to the user,
   #     0 indexed, modulo the number of players in the game.
   # @example The player immediately to the left of the user has
   #     +position_relative_to_user+ == 0
   # @example The user has
   #     +position_relative_to_user+ == <number of players> - 1
   attr_reader :position_relative_to_user
   
   # @return [Boolean] Whether or not this player has folded.
   #     +true+ if this player has folded, +false+ otherwise.
   attr_accessor :has_folded
   
   # @return [Boolean] Whether or not this player is all-in.
   #     +true+ if this player is all-in, +false+ otherwise.
   attr_accessor :is_all_in
   
   # @return [Stack] This player's stack.
   attr_reader :stack
   
   # @return [Integer] The amount this player has won or lost in the current
   #  match.  During a hand, this is a projected amount assuming that this
   #  player loses.  Positive amounts are winnings, negative amounts are losses.
   attr_accessor :chip_balance
   
   # @return [String] This player's hole cards or nil if none are known to the user.
   # @example (see MatchstateString#users_hole_cards)
   attr_accessor :hole_cards
   
   # @return [Integer] The strength of this player's hand.
   attr_accessor :poker_hand_strength
   
   # @param [String] name The name of this player.
   # @param [Integer] seat This player's seat.  This is a 1 indexed
   #     number that represents the order that the player joined the dealer.
   # @param [Integer] position_relative_to_dealer This player's position
   #     relative to the dealer, 0 indexed, modulo the number of players in
   #     the game.
   # @param [Integer] position_relative_to_user This player's position
   #     relative to the user, 0 indexed, modulo the number of players in
   #     the game.
   def initialize(name, seat, position_relative_to_dealer, position_relative_to_user, stack)
      (@name, @seat, @position_relative_to_dealer, @position_relative_to_user, @stack) =
         [name, seat, position_relative_to_dealer, position_relative_to_user, stack]
      
      @has_folded = false
      @is_all_in = false
      @current_wager_faced = 0
      @chip_balance = 0
      @number_of_chips_in_the_pot = 0
   end
   
   # @return [Boolean] Whether or not this player is active (has not folded
   #     or gone all-in).  +true+ if this player is active, +false+ otherwise.
   def is_active?
      !(@has_folded || @is_all_in)
   end
   
   # Adjusts this player's state when it takes chips from the pot.
   # @param [Integer] number_of_chips_from_the_pot The number of chips
   #  this player has won from the pot.
   def take_winnings!(number_of_chips_from_the_pot)
      take_chips_from_the_pot! number_of_chips_from_the_pot
   end
   
   # Take chips away from this player's stack.
   # @param (see Stack#take_from!)
   # @raise (see Stack#take_from!)
   def take_from_stack!(number_of_chips)
      @stack.take_from! number_of_chips
   end
   
   # All following methods are private ########################################
   private
   
   def take_chips_from_the_pot!(amount)
      @number_of_chips_in_the_pot = if amount > @number_of_chips_in_the_pot then 0 else @number_of_chips_in_the_pot - amount end
      @stack += amount
      @chip_balance += amount
   end
   
   def put_chips_in_the_pot!(amount)
      @number_of_chips_in_the_pot += amount
      @stack -= amount
      @chip_balance -= amount
   end
end
