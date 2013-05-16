
require 'mongoid'

require_relative '../../lib/mongoid_ext/player'
require_relative '../../lib/mongoid_ext/chip_stack'
# require_relative '../../lib/mongoid_ext/card'

class MatchSlice
  include Mongoid::Document

  embedded_in :match, inverse_of: :slices

  # @return [Array<Integer>] The distribution of this match's pot of chips to each player at the table.
  # @todo Shouldn't be needed now
  # field :pot_distribution, type: Array

  # Non-accumulating state
  field :hand_has_ended, type: Boolean
  field :match_has_ended, type: Boolean
  field :users_turn_to_act, type: Boolean
  field :hand_number, type: Integer
  field :minimum_wager, type: Integer
  field :seat_with_dealer_button, type: Integer
  field :seat_with_small_blind, type: Integer
  field :seat_with_big_blind, type: Integer

  field :seat_next_to_act, type: Integer

  # Current match state
  field :state_string, type: String

  # @return [String] The current betting sequence.
  field :betting_sequence, type: String

  # @return [Array<Integer>] The pot values at the beginning of the current round.
  # # @todo Not necessary
  # field :pot_values_at_start_of_round, type: Array

  # @return [Array<String>] The legal actions of the currently acting player (in ACPC format).
  field :legal_actions, type: Array

  # Related to all players

  # @return [Array<Hash<String,Object>] The hash forms of the players in this match.
  field :players, type: Array

  # @return [Array<Integer>] The amounts required for each player to call arranged by seat.
  field :amounts_to_call, type: Array

  # @return [String] The sequence of seats of acting players.
  field :player_acting_sequence, type: String

  def hand_ended?
    hand_has_ended
  end

  def match_ended?
    match_has_ended
  end

  def users_turn_to_act?
    users_turn_to_act
  end
end
