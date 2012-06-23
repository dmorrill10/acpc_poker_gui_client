#!/usr/bin/env ruby

# Join standard out and standard error
STDERR.sync = STDOUT.sync = true

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

# Local modules
require File.expand_path('../../lib/background/worker_helpers', __FILE__)
include WorkerHelpers

###########################

def log(method, variables)
  puts "#{self.class}: #{method}: #{variables.inspect}"
end

# Ensures that the map used to keep track of background processes is initialized properly
before do |job|
  @match_id_to_background_processes = {} unless @match_id_to_background_processes

  log __method__, {match_id_to_background_processes: @match_id_to_background_processes}
end

# @param [Hash] params Parameters for the dealer. Must contain values for +'match_id'+ and +'dealer_arguments'+.
Stalker.job('Dealer.start') do |params|
  match_id = match_id_param params

  dealer_arguments = param params, 'dealer_arguments', 'dealer arguments', match_id

  background_processes = @match_id_to_background_processes[match_id] || {}

  log "#{__method__}: Before: ", {
    match_id: match_id,
    dealer_arguments: dealer_arguments,
    background_processes: background_processes
  }

  # Start the dealer
  unless background_processes[:dealer]
    begin
      background_processes[:dealer] = AcpcDealerRunner.new dealer_arguments
      @match_id_to_background_processes[match_id] = background_processes
    rescue => unable_to_start_dealer_exception
      handle_exception match_id, "unable to start dealer: #{unable_to_start_dealer_exception.message}"
      raise unable_to_start_dealer_exception
    end

    # Get the player port numbers
    begin
      port_numbers = (@match_id_to_background_processes[match_id][:dealer].dealer_string).split(/\s+/)

      # Store the port numbers in the database so the web app. can access them
      match = match_instance match_id
      match.port_numbers = port_numbers
      save_match_instance match
    rescue => unable_to_retrieve_port_numbers_from_dealer_exception
      handle_exception match_id, "unable to retrieve player port numbers from the dealer: #{unable_to_retrieve_port_numbers_from_dealer_exception.message}"
      raise unable_to_retrieve_port_numbers_from_dealer_exception
    end
  end
end

# @param [Hash] params Parameters for the player proxy. Must contain values for
#  +'match_id'+, +'host_name'+, +'port_number'+, +'game_definition_file_name'+,
#  +'player_names'+, +'number_of_hands'+, and +'millisecond_response_timeout'+.
Stalker.job('PlayerProxy.start') do |params|
  match_id = match_id_param params

  background_processes = @match_id_to_background_processes[match_id] || {}

  log "#{__method__}: Before: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  unless background_processes[:player_proxy]
    host_name = param params, 'host_name', 'dealer host name', match_id
    port_number = param params, 'port_number', 'user port number', match_id
    player_names = param params, 'player_names', 'player names', match_id
    number_of_hands = param(params, 'number_of_hands', 'number of hands', match_id).to_i
    game_definition_file_name = param params, 'game_definition_file_name', 'game definition file name', match_id
    millisecond_response_timeout = param(params, 'millisecond_response_timeout', 'response timeout', match_id).to_i
    users_seat = param(params, 'users_seat', "user's seat", match_id).to_i

    begin
      game_definition = GameDefinition.parse_file game_definition_file_name
    rescue => e
      handle_exception match_id, "unable to create a game definition: #{e.message}"
      raise e
    end

    dealer_information = AcpcDealerInformation.new host_name, port_number, millisecond_response_timeout

    begin
      background_processes[:player_proxy] = WebApplicationPlayerProxy.new(
        match_id,
        dealer_information,
        users_seat,
        game_definition,
        player_names,
        number_of_hands
      )
    rescue => e
      handle_exception match_id, "unable to start the user's proxy: #{e.message}"
      raise e
    end

    @match_id_to_background_processes[match_id] = background_processes

    log "#{__method__}: After: ", {
      match_id: match_id,
      match_id_to_background_processes: @match_id_to_background_processes
    }

    # Store game definition properties in the database so the web app. can access them
    match = match_instance match_id
    match.betting_type = game_definition.betting_type
    match.number_of_hole_cards = game_definition.number_of_hole_cards
    save_match_instance match
  end
end

# @param [Hash] params Parameters for an opponent. Must contain values for
#  +'match_id'+, +'bot_start_command'+.
Stalker.job('Opponent.start') do |params|
  match_id = match_id_param params

  background_processes = @match_id_to_background_processes[match_id] || {}

  log "#{__method__}: Before: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  unless background_processes[:opponent]
    bot_start_command = param(params, 'bot_start_command', 'bot start command')

    begin
      background_processes[:opponent] = BotRunner.new bot_start_command
    rescue => unable_to_start_bot_exception
      handle_exception match_id, "unable to start bot with command \"#{bot_start_command}\": #{unable_to_start_bot_exception.message}"
      raise unable_to_start_bot_exception
    end
    @match_id_to_background_processes[match_id] = background_processes
  end

  log "#{__method__}: After: ", {
    match_id: match_id,
    match_id_to_background_processes: @match_id_to_background_processes
  }
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'action'+, and optionally +'modifier'+.
Stalker.job('PlayerProxy.play') do |params|
  match_id = match_id_param params

  action = PokerAction.new(param(params, 'action', 'poker action', match_id).to_sym, {modifier: params['modifier']})

  log "#{__method__}: Before: ", {
    match_id: match_id,
    action: action,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  begin
    @match_id_to_background_processes[match_id][:player_proxy].play! action
  rescue => e
    handle_exception match_id, "unable to take action #{action.to_acpc}: #{e.message}"
    raise e
  end

  if @match_id_to_background_processes[match_id][:player_proxy].match_ended?
    @match_id_to_background_processes.delete match_id
  end

  log "#{__method__}: After: ", {
    match_id: match_id,
    match_id_to_background_processes: @match_id_to_background_processes
  }
end

error do |e, job, args|
  # For now, all exceptions are being handled where they occur so do nothing
  # here.
end

Stalker.work
