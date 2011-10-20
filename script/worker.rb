#!/usr/bin/env ruby

# Join standard out and standard error
STDERR.sync = STDOUT.sync = true

# Include the Rails environment
RAILS_ENV = ENV.fetch("RAILS_ENV", "development")
RAILS_ROOT = File.expand_path("../..", __FILE__)

# TODO Not sure why this needs to be done
ENV["BUNDLE_GEMFILE"] = "#{RAILS_ROOT}/Gemfile"
require "bundler"
Bundler.setup(:default, RAILS_ENV.to_sym)

require "stalker"

# Local classes
#require "#{RAILS_ROOT}/lib/game_engine"
#require "#{RAILS_ROOT}/lib/bots/testing_ruby_bot"

###########################
# Rails environment
require '/home/dmorrill/workspace/acpcpokerguiclient/config/environment'

puts 'Loaded environment'

# Local classes
require 'game_core'

puts 'Loaded game_core'

require 'dealer_communication'

puts 'Loaded dealer_communication'

# Local modules
require 'application_defs'

puts 'Loaded application_defs'

include ApplicationDefs

puts 'Imported ApplicationDefs'

###########################33


@game_core = nil

Stalker.job("Game.start") do |args|
   id = args["id"]
   puts "Stalker.job: id: #{id}"
  
   # TODO Look for the correct bot to run from the arguments
   bot_arguments = {:port_number => 18791}
   begin
      port_number = 18791
      dealer_communication_service = AcpcDealerCommunicator.new(port_number)

      result = catch(:game_core_error) do
         GameCore.new('default', GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker], 1, 1, 'p2, user', dealer_communication_service)
      end

      if result.kind_of?(GameCore) then @game_core = result; else puts "ERROR: #{result}\n" end

      puts 'Created GameCore'
      
   rescue => e
      puts "Unable to connect to dealer: #{e.message}"
      raise
   end
end

Stalker.job("Game.sendCall") do |args|
   puts 'In Game.sendCall'
   
   @game_core.make_call_action
   
   puts 'Made call action'
end

Stalker.work

