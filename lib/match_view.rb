require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'

class MatchView
  attr_reader :match

  def initialize(match_id)
    @match = Match.find(match_id)
  end
  def state
    AcpcPokerTypes::MatchState.parse slice.state_string
  end
  def slice
    @match.slices.first
  end
  def pot_at_start_of_round
    slice.players.inject(0) do |sum, player|
      sum += if player['chip_contributions'].length > 1
        player['chip_contributions'][0..-2].inject(:+)
      else
        0
      end
    end
  end
  def no_limit?
    @match.betting_type == AcpcPokerTypes::GameDefinition::BETTING_TYPES[:nolimit]
  end
  def players
    slice.players.map do |player|
      if player['hole_cards'].nil? || player['folded?']
        player['hole_cards'] = AcpcPokerTypes::Hand.new
      elsif player['hole_cards'].empty?
        player['hole_cards'] = AcpcPokerTypes::Hand.new(['']*@match.number_of_hole_cards)
      else
        player['hole_cards'] = AcpcPokerTypes::Hand.from_acpc(player['hole_cards'])
      end
      player
    end
  end
  def user
    players[@match.seat - 1]
  end
  def opponents
    opp = players.dup
    opp.delete_at(@match.seat-1)
    opp
  end
end