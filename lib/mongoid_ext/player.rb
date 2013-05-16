require 'acpc_poker_types/player'

require_relative 'chip_stack'
require_relative 'card'

module AcpcPokerTypes
  class Player
    def to_h
      {
        'name' => @name,
        'seat' => @seat,
        'chip_stack' => @chip_stack,
        'chip_contributions' => @chip_contributions,
        'chip_balance' => @chip_balance,
        'hole_cards' => @hole_cards,
        'actions_taken_this_hand' => @actions_taken_this_hand,
        'folded?' => folded?,
        'all_in?' => all_in?,
        'active?' => active?
      }
    end
  end
end