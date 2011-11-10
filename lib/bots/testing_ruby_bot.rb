#!/usr/bin/env ruby

# Local classes
require File.expand_path('../proxy_bot/proxy_bot', __FILE__)
require File.expand_path('../../game/dealer_information', __FILE__)

class TestingRubyBot
   def self.play(port_number)
      dealer_info = DealerInformation.new 'localhost', port_number.to_i
      proxy_bot = ProxyBot.new dealer_info
      
      puts 'Entering game loop'
      
      proxy_bot.receive_match_state_string
      
      puts 'Got first match state'
      
      counter = 0
      while true do
         begin
            case (counter % 3)
               when 0
                  proxy_bot.send_action :call
               when 1
                  proxy_bot.send_action :fold
               when 2
                  proxy_bot.send_action :raise
            end
            counter += 1
            proxy_bot.receive_match_state_string
         rescue
            exit
         end
      end
   end
end

TestingRubyBot.play(ARGV[0].chomp) if __FILE__ == $0
