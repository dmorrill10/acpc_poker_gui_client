
# @todo Only want certain types and modules
## Local modules
#require File.expand_path('../../application_defs', __FILE__)
## Local mixins
#require File.expand_path('../../mixins/easy_exceptions', __FILE__)
## Local classes
## To connect to a dealer
#require File.expand_path('../basic_proxy', __FILE__)
## To store match snapshots
#require File.expand_path('../../game/match_state', __FILE__)

# Gems
require 'acpc_poker_types'
require 'acpc_poker_basic_proxy'
require 'acpc_poker_match_state'

# A proxy player for the web poker application.
class PlayerProxy
   include AcpcPokerTypesDefs
   
   exceptions :match_ended
   
   # @return [Array<MatchState>] Summary of the progression of the match
   #  in which, this player is participating since the last time +play!+ was called,
   #  or the initial match states before this player was given a turn to act.
   attr_reader :match_snapshots
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [String] game_definition_file_name The name of the file containing the definition of the game, of which, this match is an instance.
   # @param [String] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(dealer_information, game_definition_file_name, player_names='user p2', number_of_hands=1)
      @basic_proxy = BasicProxy.new dealer_information
      @match_state = MatchState.new(game_definition_file_name, next_match_state_string, player_names.split(/,?\s+/), number_of_hands)
      @match_snapshots = [current_match_snapshot]
      
      update_match_state! unless users_turn_to_act?
   end
   
   # Player action interface
   # @return [Array<MatchSnapshot>] Summary of the match's progression after taking the given +action+.
   def play!(action, modifier=nil)
      raise MatchEnded, "Cannot take action #{action} with modifier #{modifier} because the match has ended!" if match_ended?
      
      @basic_proxy.send_action action, modifier
      
      @match_snapshots = []
      update_match_state!
      @match_snapshots
   end
   
   private
   
   def current_match_snapshot
      @match_state.dup
   end
   
   def update_match_state!
      @match_state.update! next_match_state_string
      @match_snapshots << current_match_snapshot
      update_match_state! unless (users_turn_to_act? or match_ended?)
   end
   
   def next_match_state_string
      @basic_proxy.receive_match_state_string
   end 
   
   # @see MatchState#users_turn_to_act?
   def users_turn_to_act?      
      @match_state.users_turn_to_act?
   end
   
   # @see MatchState#match_ended?
   def match_ended?      
      @match_state.match_ended?
   end
end
