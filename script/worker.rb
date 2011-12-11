#!/usr/bin/env ruby

# Join standard out and standard error
STDERR.sync = STDOUT.sync = true

# @todo would like to remove this but Mongoid complains
#require File.expand_path('../../config/environment', __FILE__)
# Load the database configuration without the Rails environment
require File.expand_path('../../lib/config/database_config', __FILE__)

require "stalker"

###########################
# Local classes

# To store match data
require File.expand_path('../../app/models/match', __FILE__)

# To encapsulate dealer information
require 'acpc_poker_basic_proxy'

# To encapsulate poker actions
require 'acpc_poker_types'

# For game logic
require File.expand_path('../../lib/web_application_player_proxy', __FILE__)

# To run the dealer
require File.expand_path('../../lib/background/dealer_runner', __FILE__)

# For an opponent bot
require File.expand_path('../../lib/background/bot_runner', __FILE__)

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
#  +'player_names'+, and +'number_of_hands'+.
Stalker.job('PlayerProxy.start') do |params|
   dealer_information = AcpcDealerInformation.new params['host_name'], params['port_number']
   
   match_id = params['match_id']
   background_processes = @match_id_to_background_processes[match_id] || {}
   background_processes[:player_proxy] = WebApplicationPlayerProxy.new match_id,
                                          dealer_information,
                                          params['game_definition_file_name'],
                                          params['player_names'],
                                          params['number_of_hands'].to_i
   @match_id_to_background_processes[match_id] = background_processes
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'host_name'+, +'port_number'+, and +'game_definition_file_name'+.
Stalker.job('Opponent.start') do |params|
   dealer_information = AcpcDealerInformation.new params['host_name'], params['port_number']
   
   match_id = params['match_id']
   background_processes = @match_id_to_background_processes[match_id] || {}   
   background_processes[:opponent] = BotRunner.new "#{File.expand_path('../../lib/bots/testing_bot.rb', __FILE__)} #{params['port_number']}"
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'action'+, and optionally +'modifier'+.
Stalker.job('PlayerProxy.play') do |params|
   @match_id_to_background_processes[params['match_id']][:player_proxy].play! PokerAction.new(params['action'].to_sym, params['modifier'])
end

## @todo Catch errors
#error do |e, job, args|
#  Exceptional.handle(e)
#end

Stalker.work
