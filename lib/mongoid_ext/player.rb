require 'acpc_poker_types/player'

require 'lib/mongoid_ext/chip_stack'
require 'lib/mongoid_ext/pile_of_cards'

class Player
  def mongoize
    to_s
  end
  class << self
    def demongoize(string)
      Player.from_acpc(string)
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