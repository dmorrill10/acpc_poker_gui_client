require 'acpc_poker_types/card'

module AcpcPokerTypes
  class Card
    def mongoize
      to_s
    end
    class << self
      def demongoize(string)
        Card.from_acpc(string)
      end
      def mongoize(object)
        case object
        when Card then object.mongoize
        else object
        end
      end
      def evolve(object)
        mongoize(object)
      end
    end
  end
end