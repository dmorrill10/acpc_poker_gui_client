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
# Local classes

# To store match data
require File.expand_path('../../app/models/match', __FILE__)

# To encapsulate dealer information
require File.expand_path('../../lib/game/dealer_information', __FILE__)

# For game logic
require File.expand_path('../../lib/web_application_player_proxy/web_application_player_proxy', __FILE__)

# To run the dealer
require File.expand_path('../../lib/background/dealer_runner', __FILE__)

###########################

Stalker.job('Start Dealer') do |match_id, dealer_parameters|
   @match_id_to_dealer_runner_map[:match_id] = DealerRunner.start_dealer!
   port_numbers = (@match_id_to_dealer_runner_map[:match_id].dealer_string).split(/\s+/)
   
   # Store the port numbers in the database so the web app. can access them
   match = Match.find match_id
   match.port_numbers = port_numbers
end


Stalker.job('Start WebApplicationPlayerProxy') do |match_id, host_name, port_number, game_definition_file_name|
   dealer_information = DealerInformation.new host_name, port_number
   match_id = args[:match_id]
   match = Match.find match_id
   @match_id_to_web_application_player_proxy_map[match_id] = WebApplicationPlayerProxy.new match, dealer_information
end

# @todo Catch errors

Stalker.job('Take Action') do |match_id, action, modifier|
   @match_id_to_web_application_player_proxy_map[match_id].send_action action, modifier
end

Stalker.work
