
# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../pile_of_cards', __FILE__)

# List of community board cards.
class BoardCards < PileOfCards
   
   # @todo add an exception when board cards aren't added according to the +number_of_board_cards_in_each_round+.
   exceptions :too_many_board_cards
   
   # @param [Array] number_of_board_cards_in_each_round The number of board cards in each round.
   # @example The usual Texas hold'em sequence would look like this:
   #     number_of_board_cards_in_each_round == [0, 3, 1, 1]
   def initialize(number_of_board_cards_in_each_round)
      @number_of_board_cards_in_each_round = number_of_board_cards_in_each_round
   end
   
   # @see #to_str
   def to_s
      to_str
   end
   
   # @return [String] The string representation of these board cards.
   def to_str
      string = ''
      return string if self.empty?
      count = 0
      @number_of_board_cards_in_each_round.each_index do |number_of_board_cards_index|
         return string if self.length-3 == number_of_board_cards_index - 1
         string += '/'
         count_in_current_round = 0
         self.each_index do |card_index|
            next if card_index < count
            if count_in_current_round < @number_of_board_cards_in_each_round[number_of_board_cards_index]
               string += self[card_index]
               count += 1
               count_in_current_round += 1
            end
         end
      end
      string
   end
end
