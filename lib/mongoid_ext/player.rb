require 'acpc_poker_types/player'

module AcpcPokerTypes
  class Player
    def to_h
      {
        'name' => @name,
        'seat' => @seat.to_i,
        'chip_stack' => @chip_stack.to_f,
        'chip_contributions' => @chip_contributions.map { |cc| cc.to_f },
        'chip_balance' => @chip_balance.to_f,
        'hole_cards' => @hole_cards.to_acpc,
        'actions_taken_this_hand' => @actions_taken_this_hand,
        'folded?' => folded?,
        'all_in?' => all_in?,
        'active?' => active?
      }
    end
  end
end