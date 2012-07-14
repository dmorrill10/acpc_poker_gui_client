#!/usr/bin/env ruby

# Gems
require 'stalker'
require 'acpc_poker_types'

# DB configuration
require File.expand_path('../../database_config', __FILE__)

# Local classes
require File.expand_path('../../../app/models/match', __FILE__)
require File.expand_path('../../../app/helpers/player_actions_helper', __FILE__)
require File.expand_path('../../../app/helpers/application_helper', __FILE__)

class StdinStdoutPlayerProxy
  include AcpcPokerTypes
  include ApplicationHelper
  include PlayerActionsHelper

  def play!(port_number, match_name, game_definition_file_name, number_of_hands, list_of_player_names, host_name='localhost')
    # Create a new DB record
    @match = Match.create!(slices: [], match_name: match_name,
                           game_definition_key: game_definition_file_name,
                           number_of_hands: number_of_hands,
                           bot: list_of_player_names.last)

    @match_id = @match.id

    # Start the player that represents the browser operator
    player_proxy_arguments = {match_id: @match_id,
                              host_name: host_name, port_number: port_number,
                              game_definition_file_name: game_definition_file_name,
                              player_names: list_of_player_names.join(' '),
                              number_of_hands: number_of_hands,
                              millisecond_response_timeout: DEALER_MILLISECOND_TIMEOUT}

    start_background_job 'PlayerProxy.start', player_proxy_arguments

    puts 'Getting first match slice...'

    # Wait for the player to start and catch errors
    show_next_match_slice!

    puts @match_slice.to_s

    while !@match_slice.match_ended?
      if @match_slice.users_turn_to_act?
        print 'Your turn to act: '; STDOUT.flush
        action = PokerAction.new(STDIN.gets.chomp)
        Stalker.enqueue('PlayerProxy.play', match_id: @match.id, action: action.to_acpc)
      end
      show_next_match_slice!
    end
  end

  def show_next_match_slice!
    @match_id = @match.id
    @match_slice_index = 0 unless @match_slice_index
    begin
      update_match!
      raise "Unable to get match slice for match #{@match_id}" unless @match_slice
    rescue => e
      puts "Error: #{e.message}"
      exit
    end
    puts @match_slice.to_s
  end

  def params
    {match_slice_index: @match_slice_index, match_id: @match_id}
  end
end


if __FILE__ == $0
  necessary_arguments = ['<port number>', '<match name>', '<game definition file name>', '<number of hands>', '<name of player 1> <name of player 2> ...']
  unless ARGV.length > necessary_arguments.length
    puts "Usage: #{$0} #{necessary_arguments.join(' ')}"
    exit
  end
  game_definition_file_name = File.expand_path("../#{ARGV[2]}", __FILE__)
  unless FileTest.exists?(game_definition_file_name)
    puts "#{ARGV[2]} does not exist, please provide a valid game definition."
    exit
  end
  StdinStdoutPlayerProxy.new.play! ARGV[0], ARGV[1], game_definition_file_name, ARGV[3], ARGV[4..ARGV.length-1]
end
