#!/usr/bin/env ruby

# Join standard out and standard error
#STDERR.sync = STDOUT.sync = true
#
## Include the Rails environment
#RAILS_ENV = ENV.fetch("RAILS_ENV", "development")
#RAILS_ROOT = File.expand_path("../..", __FILE__)
#
## TODO Not sure why this needs to be done
#ENV["BUNDLE_GEMFILE"] = "#{RAILS_ROOT}/Gemfile"
#require "bundler"
#Bundler.setup(:default, RAILS_ENV.to_sym)
#

# @todo would like to remove this but Mongoid complains
require File.expand_path('../../config/environment', __FILE__)

require "stalker"

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

# For an opponent bot
require File.expand_path('../../lib/bots/testing_ruby_bot', __FILE__)

###########################

# Ensures that the map used to keep track of 
before do |job|
   @match_id_to_background_processes = {} unless @match_id_to_background_processes
end

# @param [Hash] params Parameters for the dealer. Must contain values for +'match_id'+ and +'dealer_arguments'+.
Stalker.job('Dealer.start') do |params|
   match_id = params['match_id']
   
   # @todo Need to keep track of this pipe?
   background_processes = @match_id_to_background_processes[match_id] || {}
   background_processes[:dealer] = AcpcDealerRunner.new params['dealer_arguments']
   @match_id_to_background_processes[match_id] = background_processes
   
   port_numbers = (@match_id_to_background_processes[match_id][:dealer].dealer_string).split(/\s+/)
   
   # Store the port numbers in the database so the web app. can access them
   match = Match.find match_id
   match.port_numbers = port_numbers
   match.save
end

# @param [Hash] params Parameters for the player proxy. Must contain values for
#  +'match_id'+, +'host_name'+, +'port_number'+, +'game_definition_file_name'+,
#  and +'number_of_hands'+.
Stalker.job('PlayerProxy.start') do |params|
   dealer_information = DealerInformation.new params['host_name'], params['port_number']
   
   match_id = params['match_id']
   background_processes = @match_id_to_background_processes[match_id] || {}
   background_processes[:player_proxy] = WebApplicationPlayerProxy.new match_id, dealer_information, params['game_definition_file_name'], params['number_of_hands']
   @match_id_to_background_processes[match_id] = background_processes
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'host_name'+, +'port_number'+, and +'game_definition_file_name'+.
Stalker.job('Opponent.start') do |params|
   dealer_information = DealerInformation.new params['host_name'], params['port_number']
   
   match_id = params['match_id']
   background_processes = @match_id_to_background_processes[match_id] || {}
   # @todo Fix this hack (just abstract out to another class that can run arbitrary bots like this)
   background_processes[:opponent] = IO.popen("#{File.expand_path('../../lib/bots/testing_ruby_bot.rb', __FILE__)} #{params['port_number']}")
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'action'+, and optionally +'modifier'+.
Stalker.job('PlayerProxy.play') do |params|
   match_id = Match.find(params['match_id']).first_match_id
   @match_id_to_background_processes[match_id][:player_proxy].play! params['action'].to_sym, params['modifier']
end

## @todo Catch errors
#error do |e, job, args|
#  Exceptional.handle(e)
#end

Stalker.work
