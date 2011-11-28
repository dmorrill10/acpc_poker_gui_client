#!/usr/bin/env ruby

# Gems
require 'stalker'

# Ruby environment for db configuration
# @todo would like to remove this but Mongoid complains
require File.expand_path('../../../config/environment', __FILE__)

# Local classes
require File.expand_path('../../../app/models/match', __FILE__)
require File.expand_path('../../acpc_poker_types', __FILE__)

class StdinStdoutPlayerProxy
   include AcpcPokerTypesDefs
   
   def play!(port_number, match_name, game_definition_file_name, number_of_hands, list_of_player_names, host_name='localhost')            
      
      # Set up the DB
      Mongoid.load!(File.expand_path('../../../config/mongoid.yml', __FILE__))
      
      # Create a new DB record
      match = Match.create!(slices: [])
      @match_id = match.id
      
      # Start the player that represents the browser operator
      player_proxy_arguments = {match_id: @match_id,
         host_name: host_name, port_number: port_number,
         game_definition_file_name: game_definition_file_name,
         number_of_hands: number_of_hands}
      Stalker.enqueue('PlayerProxy.start', player_proxy_arguments)
      
      puts 'Getting first match slice...'
      
      # Wait for the player to start and catch errors
      match_slice = show_next_match_slice!
      
      puts match_slice.to_s
      
      counter = 0
      while !match_slice.match_ended? do
         if match_slice.users_turn_to_act?
            print 'Your turn to act: '; STDOUT.flush
            action_and_modifier = STDIN.gets.chomp
            action = action_and_modifier[0]
            modifier = if 1 == action_and_modifier.length then nil else action_and_modifier end
            case action
               when ACTION_TYPES[:call]
                  Stalker.enqueue('PlayerProxy.play', match_id: @match_id, action: :call)
               when ACTION_TYPES[:fold]
                  Stalker.enqueue('PlayerProxy.play', match_id: @match_id, action: :fold)
               when ACTION_TYPES[:raise]            
                  Stalker.enqueue('PlayerProxy.play', match_id: @match_id, action: :raise, modifier: modifier)
            end
         end
         match_slice = show_next_match_slice!
      end
   end

   def show_next_match_slice!
      match_slice = next_match_slice!
      puts match_slice.to_s
      match_slice
   end
   
   # @todo document
   def next_match_slice!
      @match_slice_index = 0 unless @match_slice_index
      
      # Busy waiting for the match to be changed by the background process
      match = Match.find @match_id
      
      puts "next_match_slice: @match_id: #{@match_id}, @match_slice_index: #{@match_slice_index}, match.slices.length: #{match.slices.length}"
      
      while match.slices.length < @match_slice_index + 1
         match = Match.find @match_id
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      slice = match.slices[@match_slice_index]
      @match_slice_index += 1
      
      slice
   end
end


if __FILE__ == $0
   necessary_arguments = ['<port number>', '<match name>', '<game definition file name>', '<number of hands>', '<name of player 1> <name of player 2> ...']
   unless ARGV.length > necessary_arguments.length
      puts "Usage: ./#{$0} #{necessary_arguments.join(' ')}"
      exit
   end
   game_definition_file_name = File.expand_path("../#{ARGV[2]}", __FILE__)
   unless FileTest.exists?(game_definition_file_name)
      puts "#{ARGV[2]} does not exist, please provide a valid game definition."
      exit
   end
   StdinStdoutPlayerProxy.new.play! ARGV[0], ARGV[1], game_definition_file_name, ARGV[3], ARGV[4..ARGV.length-1]
end
