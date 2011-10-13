
# Third party


# Local modules
require 'application_defs'
require 'application_helper'
# TODO refactor models helper
require 'models_helper'


# Controller for the main game view where the table and actions are presented to the player.
# Impliments the actions in the main game view.
class PlayerActionsController < ApplicationController
   include ApplicationDefs
   include ModelsHelper
   include ApplicationHelper
   include PlayerActionsHelper
   
   # Sets up the game.  The params hash should contain a value for :port_number
   # and :game_definition_file_name.
   def index
      log 'index'
      
      port_number = params[:port_number]
      
      log "index: port_number: #{port_number}"
      
      match_name = params[:match_name]
      game_def = params[:game_definition_file_name]
      number_of_hands = params[:number_of_hands]
      random_seed = params[:random_seed]      
      player_names = params[:player_names]
      
      game_arguments = {
         :port_number => port_number,
         :match_name => match_name,
         :game_definition_file_name => game_def,
         :number_of_hands => number_of_hands,
         :random_seed => random_seed,
         :player_names => player_names
      }
      
      # TODO ensure that the background server is running by this point
      
      # Start the player that represents the browser operator
      #game_runner.start_game!(:arg => game_arguments)
      
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
      log 'update_game_state'
      
      # Update the view's state of the game
      #game_runner.update_state!
      
      # Close the pipe to the dealer if there is one open and the game has ended
      
      replace_page_contents_with_updated_game_view
   end
   
   # Leaves the game and closes the dealer
   def leave_game
      log 'leave_game'
      
      #close_dealer!
      
      replace_page_contents 'start_game/index'
   end
end

