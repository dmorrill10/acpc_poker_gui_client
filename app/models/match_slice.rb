require 'mongoid'

require_relative '../../lib/mongoid_ext/chip_stack'

class MatchSlice
  include Mongoid::Document

  embedded_in :match, inverse_of: :slices

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

  # @return [Array<String>] The legal actions of the currently acting player (in ACPC format).
  field :legal_actions, type: Array

  # Related to all players

  # @return [Array<Hash<String,Object>] The hash forms of the players in this match.
  field :players, type: Array

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