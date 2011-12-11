
# Database module
require 'mongoid'

class MatchSlice
   include Mongoid::Document
   embedded_in :match, inverse_of: :slices

   field :state_string, type: String
   
   # @return [Array<Integer>] This match's pot of chips, which consists of an array of side pot values.
   #  It is parrallel to +seat_of_players_in_side_pots+.
   field :pot, type: Array
   
   # @return [Array<Array>] The seats of the players in this match's side pots.
   #  It is parrallel to +pot+.
   field :seats_of_players_in_side_pots, type: Array
   
   # @return [Array<Hash>] The hash forms of the players in this match.
   field :players, type: Array
   
   
   
   # Match interface
   field :hand_has_ended, type: Boolean
   field :match_has_ended, type: Boolean
   field :users_turn_to_act, type: Boolean
   
   # @todo add to this
   
   def hand_ended?
      hand_has_ended
   end
   
   def match_ended?
      match_has_ended
   end
   
   def users_turn_to_act?
      users_turn_to_act
   end
   
   # @todo This is just for testing
   def to_s
      "state_string: #{state_string}, match_ended?: #{match_ended?}, hand_ended?: #{hand_ended?}, users_turn_to_act?: #{users_turn_to_act?}"
   end
end
