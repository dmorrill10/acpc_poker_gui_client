require 'mongoid'

require_relative '../../lib/mongoid_ext/chip_stack'

class MatchSlice
  include Mongoid::Document

  embedded_in :match, inverse_of: :slices

  field :match_has_ended, type: Boolean
  field :seat_with_dealer_button, type: Integer
  field :seat_with_small_blind, type: Integer
  field :seat_with_big_blind, type: Integer
  field :seat_next_to_act, type: Integer
  field :state_string, type: String
  field :balances, type: Array
  field :betting_sequence, type: String

  def match_ended?
    match_has_ended
  end
end