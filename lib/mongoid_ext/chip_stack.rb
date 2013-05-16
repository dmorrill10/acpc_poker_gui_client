require 'acpc_poker_types/chip_stack'

module AcpcPokerTypes
  class ChipStack
    class << self
      def demongoize(rational)
        ChipStack.new(rational)
      end
      def mongoize(object)
        case object
        when ChipStack then object.mongoize
        else object
        end
      end
      def evolve(object)
        mongoize(object)
      end
    end
  end
end