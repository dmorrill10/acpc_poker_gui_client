#!/usr/bin/env ruby

# Gems
require 'acpc_poker_types'
require 'acpc_poker_basic_proxy'

class TestingBot
   def self.play(port_number)
      dealer_info = AcpcDealerInformation.new 'localhost', port_number.to_i
      proxy_bot = BasicProxy.new dealer_info
      
      puts 'Entering game loop'
      
      proxy_bot.receive_match_state_string
      
      puts 'Got first match state'
      
      counter = 0
      while true do
         begin
            case (counter % 3)
               when 0
                  proxy_bot.send_action PokerAction.new(:call)
               when 1
                  proxy_bot.send_action PokerAction.new(:fold)
               when 2
                  proxy_bot.send_action PokerAction.new(:raise)
            end
            counter += 1
            proxy_bot.receive_match_state_string
         rescue
            exit
         end
      end
   end
end

if __FILE__ == $0
   unless ARGV.length > 0
      puts "Usage: ./#{$0} <port number>"
      exit
   end
   TestingBot.play ARGV[0].chomp
end
