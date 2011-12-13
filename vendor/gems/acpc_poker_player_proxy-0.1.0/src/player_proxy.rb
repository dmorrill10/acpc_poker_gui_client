
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

# Local mixins
require File.expand_path('../mixins/array_mixin', __FILE__)

# A proxy player for the web poker application.
class PlayerProxy
   include AcpcPokerTypesDefs
   
   exceptions :match_ended
   
   # @return [Array<MatchState>] Summary of the progression of the match
   #  in which, this player is participating since this object's instantiation.
   attr_reader :match_snapshots
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [String] game_definition_file_name The name of the file containing the definition of the game, of which, this match is an instance.
   # @param [String] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(dealer_information, game_definition_file_name, player_names='user p2', number_of_hands=1)
      game_definition = GameDefinition.new game_definition_file_name
      @basic_proxy = BasicProxy.new dealer_information
      @match_snapshots = [MatchState.new(game_definition, next_match_state_string, player_names.split(/,?\s+/), number_of_hands)]
      
      update_match_state! unless users_turn_to_act?
   end
   
   # Player action interface
   # @param [PokerAction] action The action to take.
   def play!(action)
      raise MatchEnded, "Cannot take action #{action} because the match has ended!" if match_ended?
      
      @basic_proxy.send_action action
      
      update_match_state!
   end
      
   private
   
   def current_match_state
      @match_snapshots.last
   end
   
   def take_match_snapshot
      first_match_state = @match_snapshots.first
      match_state = MatchState.new(first_match_state.game_definition,
                                   first_match_state.match_state_string,
                                   first_match_state.player_names,
                                   first_match_state.number_of_hands)      
      @match_snapshots.rest.each do |previous_match_states|
         match_state.update! previous_match_states.match_state_string
      end
      match_state
   end
   
   
   
   def update_match_state!
      next_match_state = take_match_snapshot.update!(next_match_state_string)
      @match_snapshots << next_match_state
      update_match_state! unless (users_turn_to_act? or match_ended?)
   end
   
   def next_match_state_string
      # @todo This BasicProxy method should have an ! at the end, since it changes its current_match_state
      @basic_proxy.receive_match_state_string
   end 
   
   # @see MatchState#users_turn_to_act?
   def users_turn_to_act?
      current_match_state.users_turn_to_act?
   end
   
   # @see MatchState#match_ended?
   def match_ended?      
      current_match_state.match_ended?
   end
end
