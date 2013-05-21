require 'match'
require 'acpc_poker_types/match_state'
require 'acpc_poker_types/game_definition'

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
  def user
    slice.players[@match.seat - 1]
  end
end