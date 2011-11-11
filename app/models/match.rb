
# Database module
require 'mongoid'

class Match
   include Mongoid::Document

   # Table parameters
   field :port_numbers, type: Array
   field :parameters, type: Hash
   
   # @todo either make this work or make this class into MatchSlice and hold an array of them in a Match
   field :first_match_id, type: String
   field :next_match_id, type: String
   
   # @todo Move the below properties to MatchSlice class
   
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
   field :is_hand_ended, type: Boolean
   field :is_match_ended, type: Boolean
   field :is_users_turn_to_act, type: Boolean
   
   # @todo add to this
   
   def hand_ended?
      is_hand_ended
   end
   
   def match_ended?
      is_match_ended
   end
   
   def users_turn_to_act?
      is_users_turn_to_act
   end
   
   # @todo This is just for testing
   def to_s
      "state_string: #{state_string}, is_users_turn_to_act: #{is_users_turn_to_act}, is_match_ended: #{is_match_ended}"
   end
end
