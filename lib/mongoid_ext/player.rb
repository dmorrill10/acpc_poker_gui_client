require 'acpc_poker_types/player'

require 'mongoid_ext/chip_stack'
require 'mongoid_ext/card'

class Player
  # @todo This is a little bit of a hack and needs to be changed whenever the player interface does, but it's super easy and works like a charm thanks to Ruby's duck-typing.
  FakeAction = Struct.new(:to_acpc, :amount_to_put_in_pot) # @todo Change to cost after update

  def mongoize
    to_h
  end
  class << self
    def demongoize(hash)
      original_stack = hash[:chip_stack] + hash[:chip_contributions].inject(:+)

      new_player = Player.join_match(
        hash[:name],
        hash[:seat],
        original_stack
      )

      new_player.start_new_hand!(
        hash[:chip_contributions].shift,
        original_stack,
        hash[:hole_cards]
      ) unless hash[:hole_cards].empty?

      flat_actions_taken_this_hand = hash[:actions_taken_this_hand].flatten

      raise if hash[:chip_contributions].length > flat_actions_taken_this_hand.length

      flat_actions_taken_this_hand.zip(
        hash[:chip_contributions]
      ).each do |action, amount|
        new_player.take_action! FakeAction.new(
          action,
          amount.to_r
        )
      end

      raise unless new_player.chip_balance == hash[:chip_balance]

      new_player
    end
    def mongoize(object)
      case object
      when Player then object.mongoize
      else object
      end
    end
    def evolve(object)
      mongoize(object)
    end
  end
end