
# Third party
require 'stalker'

# Local modules
require 'application_defs'
require 'application_helper'


# Controller for the main game view where the table and actions are presented to the player.
# Impliments the actions in the main game view.
class PlayerActionsController < ApplicationController
   include ApplicationDefs
   include ApplicationHelper
   include PlayerActionsHelper
   
   # Sets up the game.  The params hash should contain a value for :port_number
   # and :game_definition_file_name.
   def index
      @match_params = params
      
      # Start the player that represents the browser operator
      #player_proxy_arguments = {match_id: id, host_name: 'localhost', port_number: port_numbers[0], game_definition_file_name: @match_params[:game_definition_file_name]}
      #Stalker.enqueue('PlayerProxy.start', player_proxy_arguments)
      
      #log 'index'
      #
      #port_number = params[:port_number]
      #
      #log "index: port_number: #{port_number}"
      #
      #match_name = params[:match_name]
      #game_def = params[:game_definition_file_name]
      #number_of_hands = params[:number_of_hands]
      #random_seed = params[:random_seed]      
      #player_names = params[:player_names]
      #
      #game_arguments = {
      #   :port_number => port_number,
      #   :match_name => match_name,
      #   :game_definition_file_name => game_def,
      #   :number_of_hands => number_of_hands,
      #   :random_seed => random_seed,
      #   :player_names => player_names
      #}
      #
      # Start the player that represents the browser operator
      #Stalker.enqueue("Game.start", :id => match.id.to_s)
      
      # Wait for the player to start and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # @macro [new] game_action
   # Allows the user to make a +$1+ action
   def bet
      log 'bet'
      
      # Make a betting action
      result = catch(:game_core_error) do game_runner.make_bet_action end
      
      # Show the user that the proper action was taken and catch errors

      replace_page_contents_with_updated_game_view
   end

   # game_action
   def call
      log 'call'
      
      # Make a call action
      #result = catch(:game_core_error) do game_runner.make_call_action end
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # game_action
   def check
      log 'check'
      
      # Make a check action
      #result = catch(:game_core_error) do game_runner.make_check_action end
      
      #TODO Handle error
      warn "ERROR: #{result}\n" if result.kind_of?(String)
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # game_action
   def fold
      log 'fold'
      
      # Make a fold action
      #result = catch(:game_core_error) do game_runner.make_fold_action end
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # Allows the user to make a raise action
   def raise_action
      #@raise_amount = params[:amount]
      log 'raise_action'
      
      # Make a raise action
      result = catch(:game_core_error) do game_runner.make_raise_action end
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end
   
   # Updates the game state
   def update_game_state
      match_id = params[:match_id]
      
      @match = Match.find match_id
      
      replace_page_contents_with_updated_game_view
   end
   
   # Leaves the game and closes the dealer
   def leave_game
      log 'leave_game'
      
      #close_dealer!
      
      replace_page_contents 'start_game/index'
   end
end

