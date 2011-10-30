
# Local mixins
require File.expand_path('../../../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../chip_stack', __FILE__)

# A side pot of chips.
class SidePot < ChipStack

   exceptions :illegal_operation_on_side_pot
   
   # @return [Hash] The set of players involved in this side pot and the amounts they've contributed to this side pot.
   attr_reader :players_involved_and_their_amounts_contributed
   
   # @param [Player] initiating_player The player that initiated this side pot.
   # @param [Integer] initial_amount The initial value of this side pot.
   # @raise (see Stack#initialize)
   def initialize(initiating_player, initial_amount)
      @players_involved_and_their_amounts_contributed = {initiating_player => initial_amount}
      
      initiating_player.take_from_stack! initial_amount
      
      super initial_amount
   end
   
   # Have the +calling_player+ call the bet in this side pot.
   # @param [Player] calling_player The player calling the current bet in this side pot.
   def take_call!(calling_player)
      amount_contributed = @players_involved_and_their_amounts_contributed[calling_player] || 0
      
      largest_amount_contributed = @players_involved_and_their_amounts_contributed.values.max

      amount_to_call = largest_amount_contributed - amount_contributed
      
      calling_player.take_from_stack! amount_to_call
      
      @players_involved_and_their_amounts_contributed[calling_player] = amount_to_call + amount_contributed
      
      add_to! amount_to_call
   end
   
   # Have the +betting_player+ make a bet in this side pot.
   # @param [Player] betting_player The player making a bet in this side pot.
   # @param [Player] number_of_chips The number of chips to bet in this side pot.
   def take_bet!(betting_player, number_of_chips)
      raise IllegalOperationOnSidePot unless @players_involved_and_their_amounts_contributed[betting_player]
      
      betting_player.take_from_stack! number_of_chips
      
      @players_involved_and_their_amounts_contributed[betting_player] += number_of_chips
      
      add_to! number_of_chips
   end
   
   # Have the +raising_player+ make a bet in this side pot.
   # @param [Player] raising_player The player making a bet in this side pot.
   # @param [Player] number_of_chips The number of chips to bet in this side pot.
   def take_raise!(raising_player, number_of_chips_to_raise_by)
      take_call! raising_player
      take_bet! raising_player, number_of_chips_to_raise_by
   end
   
   # Distribute chips to all winning players
   def distribute_chips!
      distribute_chips_r! list_of_players_who_have_not_folded
   end
   
   private
   
   # return [Array] The list of players that have contributed to this side pot that have not folded.
   def list_of_players_who_have_not_folded
      @players_involved_and_their_amounts_contributed.keys.reject { |player| player.has_folded }
   end
   
   def distribute_chips_r!(list_of_players)
      return if 0 == @value
      
      if 1 == list_of_players.length
         #log "distribute_winnings_r!: amount_to_distribute: #{amount_to_distribute}"
         
         list_of_players[0].take_winnings! value
         take_from! value
      else
         #distribute_winnings_amongst_multiple_players! list_of_players, amount_to_distribute
      end
   end
   
   # TODO This doesn't work if the player with the strongest hand is in a smaller pot than other players, but this is only an issue in multiplayer. When I do deal with this, I'll have to do a loop until there are no more chips in the pot except the overflow.
   def distribute_winnings_amongst_multiple_players!(list_of_players, amount_to_distribute)
      # Find the stength of the strongest hand
      strength_of_the_strongest_hand = (list_of_players.max { |player1, player2| player1.hand_strength <=> player2.hand_strength}).hand_strength
      
      log "distribute_winnings_amongst_multiple_players: strength_of_the_strongest_hand: #{strength_of_the_strongest_hand}"
         
      # Find all the players that have hands as strong as the strongest hand
      winning_players = list_of_players.select { |player| strength_of_the_strongest_hand == player.hand_strength }
      if 1 == winning_players.length
         # If one player wins outright, set the number of chips that all other players have in the pot to zero
         (list_of_players.reject { |player| player == winning_players[0] }).map { |player| player.number_of_chips_in_the_pot = 0 }
         
         # Recurse
         distribute_winnings_r! winning_players, amount_to_distribute
      else
         # Find the smallest side-pot
         # The smallest side-pot is equal to the smallest amount put in the pot by a winning player multiplied by the number of players that have put as many or more chips in the pot plus all the smaller amounts put in by folded players
         player_who_put_the_least_in_the_pot = list_of_players.min { |player1, player2| player1.number_of_chips_in_the_pot <=> player2.number_of_chips_in_the_pot }
         smallest_amount_from_a_winning_player = player_who_put_the_least_in_the_pot.number_of_chips_in_the_pot
         smaller_amounts_from_folded_players = list_of_players_who_have_folded.inject(0) { |sum, player| sum + player.number_of_chips_in_the_pot }
         
         log "distribute_winnings_amongst_multiple_players: smaller_amounts_from_folded_players: #{smaller_amounts_from_folded_players}"
            
         smallest_side_pot = (smallest_amount_from_a_winning_player * list_of_players.length) + smaller_amounts_from_folded_players
            
         # Split the smallest side-pot among the winners
         amount_each_player_wins = (smallest_side_pot/winning_players.length).floor
         winning_players.each { |player| player.take_winnings! amount_each_player_wins }
            
         # Remove chips from the pot
         list_of_players_who_have_folded.each { |player| player.number_of_chips_in_the_pot = 0 }
         non_winning_players_at_showdown = list_of_players.reject { |player| strength_of_the_strongest_hand == player.hand_strength }
         non_winning_players_at_showdown.each { |player| player.number_of_chips_in_the_pot -= smallest_amount_from_a_winning_player }
         # TODO Is the right behaviour to leave excess chips in the pot when they don't divide easily?
         number_of_chips_taken_out_of_the_pot = amount_each_player_wins * winning_players.length
         @pot_carry_over = smallest_side_pot - number_of_chips_taken_out_of_the_pot
         
         log "distribute_winnings_amongst_multiple_players: number_of_chips_taken_out_of_the_pot: #{number_of_chips_taken_out_of_the_pot}, smallest_side_pot: #{smallest_side_pot}, @pot_carry_over: #{@pot_carry_over}"
         
         new_amount_to_distribute = amount_to_distribute - smallest_side_pot
            
         # Distribute the rest of the pot to the players who won a larger side-pot
         players_who_won_a_larger_side_pot = winning_players.reject { |player| player_who_put_the_least_in_the_pot == player }
         
         log "distribute_winnings_amongst_multiple_players: new_amount_to_distribute: #{new_amount_to_distribute}, amount_each_player_wins: #{amount_each_player_wins}, winning_players.length: #{winning_players.length}"
         
         distribute_winnings_r! players_who_won_a_larger_side_pot, new_amount_to_distribute
      end
   end
end
