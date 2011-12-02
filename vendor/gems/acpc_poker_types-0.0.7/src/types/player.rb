
# Local classes
require File.expand_path('../chip_stack', __FILE__)

# Class to model a player.
class Player   
   # @return [String] The name of this player.
   attr_reader :name
   
   # @return [Integer] This player's seat.  This is a 1 indexed
   #     number that represents the order that the player joined the dealer.
   attr_reader :seat
   
   # @return [Integer] This player's position relative to the dealer,
   #     0 indexed, modulo the number of players in the game.
   # @example (see MatchstateString#position_relative_to_dealer)
   attr_accessor :position_relative_to_dealer
   
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
   
   # @return [ChipStack] This player's chip stack.
   attr_accessor :chip_stack
   
   # @return [Integer] The amount this player has won or lost in the current
   #  match.  During a hand, this is a projected amount assuming that this
   #  player loses.  Positive amounts are winnings, negative amounts are losses.
   attr_accessor :chip_balance
   
   # @return [Hand] This player's hole cards or nil if none are known to the user.
   # @example (see MatchstateString#users_hole_cards)
   attr_accessor :hole_cards
   
   # @param [String] name The name of this player.
   # @param [Integer] seat This player's seat.  This is a 1 indexed
   #     number that represents the order that the player joined the dealer.
   # @param [Integer] position_relative_to_dealer This player's position
   #     relative to the dealer, 0 indexed, modulo the number of players in
   #     the game.
   # @param [Integer] position_relative_to_user This player's position
   #     relative to the user, 0 indexed, modulo the number of players in
   #     the game.
   # @param [ChipStack] chip_stack This player's chip stack.
   # @param [Integer] chip_balance This player's chip balance.
   def initialize(name, seat, position_relative_to_dealer, position_relative_to_user,
                  chip_stack, chip_balance=0, hole_cards=nil, has_folded=false,
                  is_all_in=false)
      (@name, @seat, @position_relative_to_dealer, @position_relative_to_user,
       @chip_stack, @chip_balance, @hole_cards, @has_folded, @is_all_in) =
         [name, seat, position_relative_to_dealer, position_relative_to_user,
          chip_stack, chip_balance, hole_cards, has_folded, is_all_in]
   end
   
   # @return [String] String representation of this player.
   def to_s
      to_hash.to_s
   end
   
	# @return [Hash] Hash map representation of this player.
	def to_hash
      hash_rep = {}
		self.instance_variables.each { |var| hash_rep.store(var.to_s.delete("@"), self.instance_variable_get(var)) }
		hash_rep["chip_stack"] = @chip_stack.value
		hash_rep["hole_cards"] = @hole_cards.to_s
		hash_rep
	end
	
	def folded?
      @has_folded
	end
	
	def all_in?
      @is_all_in
	end
   
   # @return [Boolean] Whether or not this player is active (has not folded
   #     or gone all-in).  +true+ if this player is active, +false+ otherwise.
   def is_active?
      !(folded? || all_in?)
   end
   
   # Adjusts this player's state when it takes chips from the pot.
   # @param [Integer] number_of_chips_from_the_pot The number of chips
   #  this player has won from the pot.
   def take_winnings!(number_of_chips_from_the_pot)
      @chip_stack.add_to! number_of_chips_from_the_pot
      @chip_balance += number_of_chips_from_the_pot
   end
   
   # Take chips away from this player's chip stack.
   # @param (see ChipStack#take_from!)
   # @raise (see ChipStack#take_from!)
   def take_from_chip_stack!(number_of_chips)
      @chip_stack.take_from! number_of_chips
      @chip_balance -= number_of_chips
   end
end
