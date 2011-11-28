#!/home/dmorrill/.rvm/rubies/ruby-1.9.2-p290/bin/ruby

# Rails environment
require '/home/dmorrill/workspace/acpcpokerguiclient/config/environment'

puts 'Loaded environment'

# Local classes
require 'game_core'

puts 'Loaded game_core'

require 'dealer_communication'

puts 'Loaded dealer_communication'

# Local modules
require 'acpc_poker_types'

puts 'Loaded acpc_poker_types'

include AcpcPokerTypesDefs

puts 'Imported AcpcPokerTypesDefs'

# TODO Abstract this out into BotCore
port_number = if ARGV[0] then ARGV[0] else 18374 end
dealer_communication_service = AcpcDealerCommunicator.new(port_number)

result = catch(:game_core_error) do
   GameCore.new('default', GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker], 1, 1, 'p2, user', dealer_communication_service)
end

if result.kind_of?(GameCore) then game_core = result; else puts "ERROR: #{result}\n" end

puts 'Entering game loop'

counter = 0
while !(game_core.hand_ended?) do
   if game_core.users_turn_to_act?
      case (counter % 3)
         when 0
            game_core.make_call_action
         when 1
            game_core.make_raise_action
         when 2
            game_core.make_fold_action
      end
      counter += 1
   end
   game_core.update_state!
end

puts "game_core.hand_ended?: #{game_core.hand_ended?}"

dealer_communication_service.close               # Close the socket when done

exit 0
