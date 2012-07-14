#!/usr/bin/env ruby

# Join standard out and standard error
STDERR.sync = STDOUT.sync = true

require "stalker"

# Load the database configuration without the Rails environment
require_relative '../database_config'

# To store match data
require_relative '../../app/models/match'

# To encapsulate dealer information
require 'acpc_poker_basic_proxy'

# To encapsulate poker actions
require 'acpc_poker_types'

# For game logic
require_relative '../web_application_player_proxy'

# To run the dealer
require 'acpc_dealer'

# For an opponent bot
require 'dmorrill10-utils/process_runner'

# Helpers
require_relative 'worker_helpers'

include WorkerHelpers

# Ensures that the map used to keep track of background processes is initialized properly
before do |job|
  @match_id_to_background_processes = {} unless @match_id_to_background_processes

  log __method__, {match_id_to_background_processes: @match_id_to_background_processes}
end

# @param [Hash] params Parameters for the dealer. Must contain values for +'match_id'+ and +'dealer_arguments'+.
Stalker.job('Dealer.start') do |params|
  match_id = params.retrieve_match_id_or_raise_exception
  dealer_arguments = {
    match_name: params.retrieve_parameter_or_raise_exception('match_name'),
    game_def_file_name: params.retrieve_parameter_or_raise_exception('game_def_file_name'),
    hands: params.retrieve_parameter_or_raise_exception('number_of_hands'),
    random_seed: params.retrieve_parameter_or_raise_exception('random_seed'),
    player_names: params.retrieve_parameter_or_raise_exception('player_names'),
    options: (params['options'] || {})
  }
  log_directory = params['log_directory']
  
  background_processes = @match_id_to_background_processes[match_id] || {}

  log "Stalker.job('Dealer.start'): Before: ", {
    match_id: match_id,
    dealer_arguments: dealer_arguments,
    log_directory: log_directory,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  # Start the dealer
  unless background_processes[:dealer]
    begin
      background_processes[:dealer] = DealerRunner.start(
        dealer_arguments,
        log_directory
      )
      @match_id_to_background_processes[match_id] = background_processes
    rescue => unable_to_start_dealer_exception
      handle_exception match_id, "unable to start dealer: #{unable_to_start_dealer_exception.message}"
      raise unable_to_start_dealer_exception
    end

    # Get the player port numbers
    begin
      port_numbers = @match_id_to_background_processes[match_id][:dealer][:port_numbers]

      # Store the port numbers in the database so the web app. can access them
      match = match_instance match_id
      match.port_numbers = port_numbers
      save_match_instance match
    rescue => unable_to_retrieve_port_numbers_from_dealer_exception
      handle_exception match_id, "unable to retrieve player port numbers from the dealer: #{unable_to_retrieve_port_numbers_from_dealer_exception.message}"
      raise unable_to_retrieve_port_numbers_from_dealer_exception
    end
  end

  log "Stalker.job('Dealer.start'): After: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }
end

# @param [Hash] params Parameters for the player proxy. Must contain values for
#  +'match_id'+, +'host_name'+, +'port_number'+, +'game_definition_file_name'+,
#  +'player_names'+, +'number_of_hands'+, and +'millisecond_response_timeout'+.
Stalker.job('PlayerProxy.start') do |params|
  match_id = params.retrieve_match_id_or_raise_exception

  background_processes = @match_id_to_background_processes[match_id] || {}

  log "Stalker.job('PlayerProxy.start'): Before: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  unless background_processes[:player_proxy]
    host_name = params.retrieve_parameter_or_raise_exception 'host_name'
    port_number = params.retrieve_parameter_or_raise_exception 'port_number'
    player_names = params.retrieve_parameter_or_raise_exception 'player_names'
    number_of_hands = params.retrieve_parameter_or_raise_exception('number_of_hands').to_i
    game_definition_file_name = params.retrieve_parameter_or_raise_exception 'game_definition_file_name'
    millisecond_response_timeout = params.retrieve_parameter_or_raise_exception('millisecond_response_timeout').to_i
    users_seat = params.retrieve_parameter_or_raise_exception('users_seat').to_i

    begin
      game_definition = GameDefinition.parse_file game_definition_file_name
    rescue => e
      handle_exception match_id, "unable to create a game definition: #{e.message}"
      raise e
    end

    # @todo Move AcpcDealerInformation from basic_proxy gem to acpc_dealer as DealerInformation
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

    log "Stalker.job('PlayerProxy.start'): After: ", {
      match_id: match_id,
      background_processes: background_processes,
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
  match_id = params.retrieve_match_id_or_raise_exception

  background_processes = @match_id_to_background_processes[match_id] || {}

  log "Stalker.job('Opponent.start'): Before: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }

  unless background_processes[:opponent]
    bot_start_command = params.retrieve_parameter_or_raise_exception 'bot_start_command'

    begin
      background_processes[:opponent] = ProcessRunner.go bot_start_command
    rescue => unable_to_start_bot_exception
      handle_exception match_id, "unable to start bot with command \"#{bot_start_command}\": #{unable_to_start_bot_exception.message}"
      raise unable_to_start_bot_exception
    end
    @match_id_to_background_processes[match_id] = background_processes
  end

  log "Stalker.job('Opponent.start'): After: ", {
    match_id: match_id,
    background_processes: background_processes,
    match_id_to_background_processes: @match_id_to_background_processes
  }
end

# @param [Hash] params Parameters for an opponent. Must contain values for +'match_id'+, +'action'+, and optionally +'modifier'+.
Stalker.job('PlayerProxy.play') do |params|
  match_id = params.retrieve_match_id_or_raise_exception

  action = PokerAction.new(
    params.retrieve_parameter_or_raise_exception('action').to_sym, 
    {modifier: params['modifier']}
  )

  log "Stalker.job('PlayerProxy.play'): Before: ", {
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

  log "Stalker.job('PlayerProxy.play'): After: ", {
    match_id: match_id,
    match_id_to_background_processes: @match_id_to_background_processes
  }
end

error do |e, job, args|
  # For now, all exceptions are being handled where they occur so do nothing
  # here.
end

Stalker.work
