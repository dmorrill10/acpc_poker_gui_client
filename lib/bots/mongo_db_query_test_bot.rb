#!/usr/bin/env ruby

# Local classes
require File.expand_path('../../game/dealer_information', __FILE__)
require File.expand_path('../proxy_bot/domain_types/matchstate_string', __FILE__)
require File.expand_path('../proxy_bot/proxy_bot', __FILE__)
require File.expand_path('../../../app/models/match', __FILE__)

class MongoDbQueryTestBot
   def self.play
      
      unless ARGV[0] && ARGV[1]
         puts "Usage: ./#{$0} <port number> <database ID>"
         exit
      end
      
      # Set up the DB
      Mongoid.load!(File.expand_path('../../../config/mongoid.yml', __FILE__))
      
      port_number = ARGV[0] || 18374
      dealer_info = DealerInformation.new 'localhost', port_number
      proxy_bot = ProxyBot.new dealer_info
      
      puts 'Connected to dealer'
      
      proxy_bot.receive_match_state_string
      
      # Query the DB
      match = Match.find(ARGV[1].to_s)
      
      puts "Got match: match.id: #{match.id}"
      
      puts "Retrieving first match state from DB: #{match.state}"
      
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
            
            match = Match.find(ARGV[1].to_s)
            
            puts "Retrieving match state from DB: #{match.state}"
         rescue
            exit
         end
      end
   end
end


MongoDbQueryTestBot.play if __FILE__ == $0
