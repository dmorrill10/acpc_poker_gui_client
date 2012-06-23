
require 'mongoid'

class MatchSlice
   include Mongoid::Document
   
   embedded_in :match, inverse_of: :slices

   field :state_string, type: String
   
   # @return [Array<Integer>] The pot values at the beginning of the current round.
   field :pot_values_at_start_of_round, type: Array
   
   # @return [Array<Integer>] The distribution of this match's pot of chips to each player at the table.
   field :pot_distribution, type: Array
   
   # @return [Array<Hash>] The hash forms of the players in this match.
   field :players, type: Array
   
   # @return [Hash<Symbol, String>] Information about turns and blinds.
   field :player_turn_information, type: Hash
   
   # @return [String] The current betting sequence.
   field :betting_sequence, type: String
   
   # @return [String] The sequence of seats of acting players.
   field :player_acting_sequence, type: String
   
   # @return [Array<String>] The legal actions of the currently acting player (in ACPC format).
   field :legal_actions, type: Array
   
   # Match interface
   field :hand_has_ended, type: Boolean
   field :match_has_ended, type: Boolean
   field :users_turn_to_act, type: Boolean
   
   field :minimum_wager, type: Integer
   
   # @return [Hash<String, Integer>] The amounts required for each player to call.
   #  Each element contains a mapping between a player's name and the amount that player has put in the pot to call.
   field :amounts_to_call, type: Hash
   
   field :hand_number, type: Integer
   
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
