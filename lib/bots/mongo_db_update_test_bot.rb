#!/usr/bin/env ruby

# Local classes
require File.expand_path('../../game/dealer_information', __FILE__)
require File.expand_path('../proxy_bot/domain_types/matchstate_string', __FILE__)
require File.expand_path('../proxy_bot/proxy_bot', __FILE__)
require File.expand_path('../../../app/models/match', __FILE__)

class MongoDbUpdateTestBot
   def self.play(dealer_info, match_id=nil)
      
      # Set up the DB
      match = nil
      unless match_id
         Mongoid.configure do |config|
            config.master = Mongo::Connection.new.db("mongo_db_test")
         end
         match = Match.create
         match_id = match.id
      else
         match = Match.find match_id
      end
      
      puts "Setup match: match_id: #{match_id}"
      
      proxy_bot = ProxyBot.new dealer_info
      
      puts 'Entering game loop'
      
      match_state_string = proxy_bot.receive_match_state_string
      
      puts "Inserting first match state into DB: #{match_state_string}"
      
      # Insert into DB
      match.update_attributes!(state: match_state_string)
      
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
            match_state_string = proxy_bot.receive_match_state_string
            
            puts "Got match state: match_state_string: #{match_state_string}"
            
            # Insert into DB
            match.update_attributes!(state: match_state_string)
         rescue
            exit
         end
      end
   end
end

if __FILE__ == $0
   port_number = ARGV[0] || 18374
   MongoDbUpdateTestBot.play DealerInformation.new('localhost', port_number)
end
