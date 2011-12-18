
# @todo Only need certain classes
## Local modules
#require File.expand_path('../../acpc_poker_types', __FILE__)
## Local mixins
#require File.expand_path('../../mixins/easy_exceptions', __FILE__)
## Local classes
#require File.expand_path('../../bots/proxy_bot/proxy_bot', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/board_cards', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/card', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/chip_stack', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/game_definition', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/hand', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/matchstate_string', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/player', __FILE__)
#require File.expand_path('../../bots/proxy_bot/domain_types/side_pot', __FILE__)

# Gems
require 'acpc_poker_types'
require 'acpc_poker_match_state'
require 'acpc_poker_player_proxy'

require File.expand_path('../config/database_config', __FILE__)
require File.expand_path('../../app/models/match', __FILE__)


# A proxy player for the web poker application.
class WebApplicationPlayerProxy
   include AcpcPokerTypesDefs
   
   exceptions :unable_to_create_match_slice
   
   # @param [String] match_id The ID of the match in which this player is participating.
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   # @param [String] game_definition_file_name The name of the file containing the definition of the game, of which, this match is an instance.
   # @param [String] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(match_id, dealer_information, game_definition_file_name, player_names='user p2', number_of_hands=1)
      @match_id = match_id
      @match_slice_index = 0
      @player_proxy = PlayerProxy.new dealer_information, game_definition_file_name, player_names, number_of_hands
      update_match_state!
   end
   
   # Player action interface
   # @see PlayerProxy#play!
   def play!(action)      
      @player_proxy.play! action
      update_match_state!
   end
      
   def update_match_state!
      number_of_match_states_saved = 0
      @player_proxy.match_snapshots.rest(@match_slice_index).each do |match_state|
         update_database! match_state
         number_of_match_states_saved += 1
      end
      @match_slice_index += number_of_match_states_saved
   end
   
   def update_database!(match_state)
      match = Match.find(@match_id)
      
      # @todo This only works for two player
      seats_of_players_in_side_pots = match_state.pot.players_involved_and_their_amounts_contributed.keys.map { |player| player.seat }
      players = match_state.players.map { |player| player.to_hash }
      
      pot = [match_state.pot.players_involved_and_their_amounts_contributed.inject({}) do
                |hash, player_and_value|
                hash[player_and_value[0].name] = player_and_value[1]
                hash
            end]
      
      pot_distribution = [match_state.pot.players_involved_and_their_amounts_received.inject({}) do
                             |hash, player_and_value|
                             hash[player_and_value[0].name] = player_and_value[1]
                             hash
                         end]
      
      begin
         match.slices.create!(state_string: match_state.match_state_string.to_s,
                              pot: pot,
                              pot_distribution: pot_distribution,
                              seats_of_players_in_side_pots: seats_of_players_in_side_pots,
                              hand_has_ended: match_state.hand_ended?,
                              match_has_ended: match_state.match_ended?,
                              users_turn_to_act: match_state.users_turn_to_act?,
                              players: players)
         match.save
      rescue => e
         raise UnableToCreateMatchSlice, e.message
      end
   end
end
