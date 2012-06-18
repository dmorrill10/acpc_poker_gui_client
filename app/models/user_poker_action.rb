
# Database module
require 'mongoid'
Mongoid.logger = nil

class UserPokerAction
   include Mongoid::Document
   
   attr_accessor :minimum_bet
   
   def self.include_poker_action
      field :poker_action, type: String
      validates_presence_of :poker_action
   end
   
   def self.include_modifier
      field :modifier, type: Integer
      # @todo Don't know how to set the minimum bet dynamically
      validates_numericality_of :modifier, greater_than: 0, only_integer: true
      # @todo Can't get a condition like this to work.
      #validates_presence_of :modifier, if: 'r' == self.poker_action
   end
   
   def self.include_match_id
      field :match_id, type: String
      validates_presence_of :match_id
   end
   
   def self.include_match_slice_index
      field :match_slice_index, type: Integer
      validates_presence_of :match_slice_index
      validates_numericality_of :match_slice_index, only_integer: true
   end
   
   include_poker_action
   include_modifier
   include_match_id
   include_match_slice_index
end
