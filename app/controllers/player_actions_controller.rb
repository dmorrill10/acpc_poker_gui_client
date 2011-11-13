
# Third party
require 'stalker'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'
require File.expand_path('../../../lib/bots/proxy_bot/domain_types/matchstate_string', __FILE__)

# Controller for the main game view where the table and actions are presented to the player.
# Impliments the actions in the main game view.
class PlayerActionsController < ApplicationController
   include ApplicationDefs
   include ApplicationHelper
   include PlayerActionsHelper
   
   # Sets up the game.  The params hash should contain a value for :port_number
   # and :game_definition_file_name.
   def index
      @match_params = {match_id: params[:match_id], port_number: params[:port_number],
         match_name: params[:match_name],
         game_definition_file_name: params[:game_definition_file_name],
         number_of_hands: params[:number_of_hands],
         random_seed: params[:random_seed], player_names: params[:player_names]}
      
      # Start the player that represents the browser operator
      player_proxy_arguments = {match_id: @match_params[:match_id],
         host_name: 'localhost', port_number: @match_params[:port_number],
         game_definition_file_name: @match_params[:game_definition_file_name],
         player_names: @match_params[:player_names],
         number_of_hands: @match_params[:number_of_hands]}
      Stalker.enqueue('PlayerProxy.start', player_proxy_arguments)
      
      # Wait for the player to start and catch errors
      update_match!
      
      replace_page_contents_with_updated_game_view
   end

   # @macro [new] game_action
   # Allows the user to make a +$1+ action
   def bet
      
      # Show the user that the proper action was taken and catch errors

      replace_page_contents_with_updated_game_view
   end

   # game_action
   def call      
      Stalker.enqueue('PlayerProxy.play', match_id: params[:match_id], action: :call)
      update_match!
      
      replace_page_contents_with_updated_game_view
   end

   # game_action
   def check
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # game_action
   def fold
      Stalker.enqueue('PlayerProxy.play', match_id: params[:match_id], action: :fold)
      update_match!
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end

   # Allows the user to make a raise action
   def raise_action
      modifier = params[:amount]
      Stalker.enqueue('PlayerProxy.play', match_id: params[:match_id], action: :raise, modifier: modifier)
      update_match!
      
      # Show the user that the proper action was taken and catch errors
      
      replace_page_contents_with_updated_game_view
   end
   
   # Updates the game state
   def update_game_state
      update_match!
      replace_page_contents_with_updated_game_view
   end
   
   # Leaves the game and closes the dealer
   def leave_game      
      # @todo Still have no idea how this will effect background processes, was doing 'close_dealer!' in the old version
      
      redirect_to root_path, :remote => true
   end
end

