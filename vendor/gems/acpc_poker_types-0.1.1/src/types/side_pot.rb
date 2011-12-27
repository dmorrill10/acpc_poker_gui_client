
# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../board_cards', __FILE__)
require File.expand_path('../chip_stack', __FILE__)

# A side-pot of chips.
class SidePot < ChipStack
   
   exceptions :illegal_operation_on_side_pot, :no_chips_to_distribute, :no_players_to_take_chips
   
   # @return [Hash] The set of players involved in this side-pot and the amounts they've contributed to this side-pot.
   attr_reader :players_involved_and_their_amounts_contributed
   
   # @return [Hash] The set of players involved in this side-pot and the amounts they've received from this side-pot.
   attr_reader :players_involved_and_their_amounts_received
   
   # @param [Player] initiating_player The player that initiated this side-pot.
   # @param [Integer] initial_amount The initial value of this side-pot.
   # @raise (see Stack#initialize)
   def initialize(initiating_player, initial_amount)
      initiating_player.take_from_chip_stack! initial_amount
      @players_involved_and_their_amounts_contributed = {initiating_player => initial_amount}
      @players_involved_and_their_amounts_received = {}
      
      super initial_amount
   end
      
   # @todo
   def contribute!(player, amount)
      player.take_from_chip_stack! amount
      @players_involved_and_their_amounts_contributed[player] = amount
      
      @value = @players_involved_and_their_amounts_contributed.values.inject(0){ |sum, current_amount| sum += current_amount }
   end
   
   # Have the +calling_player+ call the bet in this side-pot.
   # @param [Player] calling_player The player calling the current bet in this side-pot.
   # @return [Integer] The number of chips put in this side-pot.
   def take_call!(calling_player)      
      # @todo This only applies in no-limit and multiplayer and is not correct yet.
      #  If the calling player has a smaller stack than the amount to call, a
      #  new side-pot needs to be created where all players who already contributed
      #  to this one, have a portion of their chips moved into it, while the other
      #  portion stays in this side-pot. If this happens in two player, the
      #  player who contributed the most should simply be refunded the extra amount.
      #  This should be handled in Pot.
      #if calling_player.chip_stack.value < amount_to_call
      #   amount_to_call = calling_player.chip_stack.value
      #   players_who_contributed_the_most = @players_involved_and_their_amounts_contributed.keys.collect { |player| largest_amount_contributed == @players_involved_and_their_amounts_contributed[player] }
      #end
      
      amount_for_this_player_to_call = amount_to_call calling_player
      calling_player.take_from_chip_stack! amount_for_this_player_to_call
      @players_involved_and_their_amounts_contributed[calling_player] += amount_for_this_player_to_call
      add_to! amount_for_this_player_to_call
   end
   
   def amount_to_call(player)
      @players_involved_and_their_amounts_contributed[player] = 0 unless @players_involved_and_their_amounts_contributed[player]
      
      amount_contributed =  @players_involved_and_their_amounts_contributed[player]
      largest_amount_contributed = @players_involved_and_their_amounts_contributed.values.max
      largest_amount_contributed - amount_contributed
   end
   
   # Have the +betting_player+ make a bet in this side-pot.
   # @param [Player] betting_player The player making a bet in this side-pot.
   # @param [Player] number_of_chips The number of chips to bet in this side-pot.
   def take_bet!(betting_player, number_of_chips)
      raise IllegalOperationOnSidePot unless @players_involved_and_their_amounts_contributed[betting_player]
      
      betting_player.take_from_chip_stack! number_of_chips
      
      @players_involved_and_their_amounts_contributed[betting_player] += number_of_chips
      
      add_to! number_of_chips
   end
   
   # Have the +raising_player+ make a bet in this side-pot.
   # @param [Player] raising_player The player making a bet in this side-pot.
   # @param [Player] number_of_chips The number of chips to bet in this side-pot.
   def take_raise!(raising_player, number_of_chips_to_raise_to)
      puts "   take_raise!: raising_player: #{raising_player}, number_of_chips_to_raise_to: #{number_of_chips_to_raise_to}, @players_involved_and_their_amounts_contributed: #{@players_involved_and_their_amounts_contributed}"
      
      take_call! raising_player
      take_bet! raising_player, number_of_chips_to_raise_to - @players_involved_and_their_amounts_contributed[raising_player]
   end
   
   # Distribute chips to all winning players
   # @param [BoardCards] board_cards The community board cards.
   def distribute_chips!(board_cards)
      raise NoChipsToDistribute unless @value > 0
      
      players_to_distribute_to = list_of_players_who_have_not_folded
      
      raise NoPlayersToTakeChips unless players_to_distribute_to.length > 0
      
      if 1 == players_to_distribute_to.length
         winning_player = players_to_distribute_to[0]
         @players_involved_and_their_amounts_received[winning_player] = @value
         winning_player.take_winnings! @value
         
         take_from! @value
      elsif
         distribute_winnings_amongst_multiple_players! players_to_distribute_to, board_cards
      end
      
      @players_involved_and_their_amounts_contributed = {}
   end
   
   private
   
   # return [Array] The list of players that have contributed to this side-pot who have not folded.
   def list_of_players_who_have_not_folded
      @players_involved_and_their_amounts_contributed.keys.reject { |player| player.has_folded }
   end
   
   def distribute_winnings_amongst_multiple_players!(list_of_players, board_cards)
      strength_of_the_strongest_hand = 0
      list_of_strongest_hands = []
      winning_players = []
      list_of_players.each do |player|
         hand_strength = PileOfCards.new(board_cards + player.hole_cards).to_poker_hand_strength         
         if hand_strength >= strength_of_the_strongest_hand
            strength_of_the_strongest_hand = hand_strength
            if !list_of_strongest_hands.empty? && hand_strength > list_of_strongest_hands.max
               winning_players = [player]
               list_of_strongest_hands = [hand_strength]
            else
               list_of_strongest_hands << hand_strength
               winning_players << player
            end
         end         
      end
      
      # Split the side-pot's value among the winners
      amount_each_player_wins = (@value/winning_players.length).floor
      winning_players.each do |player|
         @players_involved_and_their_amounts_received[player] = amount_each_player_wins
         player.take_winnings! amount_each_player_wins
      end

      # Remove chips from this side-pot
      take_from! amount_each_player_wins * winning_players.length
   end
end
