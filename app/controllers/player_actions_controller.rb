
# Gems
require 'stalker'

# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'
require 'user_poker_action'

# Controller for the main game view where the table and actions are presented to the player.
# Implements the actions in the main match view.
class PlayerActionsController < ApplicationController
   include ApplicationDefs
   include ApplicationHelper
   include PlayerActionsHelper
   
   def index
      @match_params = {
         match_id: params[:match_id], 
         port_number: params[:port_number],
         match_name: params[:match_name],
         game_definition_file_name: params[:game_definition_file_name],
         number_of_hands: params[:number_of_hands],
         seat: params[:seat],
         random_seed: params[:random_seed], 
         player_names: params[:player_names],
         millisecond_response_timeout: params[:millisecond_response_timeout]
      }
      
      @match_id = @match_params[:match_id]
      @match = Match.find @match_id
      if @match && @match.slices.length > 0
         @match_slice = @match.slices.last
         @match_slice_index = @match.slices.length
      else
         player_proxy_arguments = {
            match_id: @match_params[:match_id],
            host_name: 'localhost', port_number: @match_params[:port_number],
            game_definition_file_name: @match_params[:game_definition_file_name],
            player_names: @match_params[:player_names],
            number_of_hands: @match_params[:number_of_hands],
            millisecond_response_timeout: @match_params[:millisecond_response_timeout],
            users_seat: (@match_params[:seat].to_i - 1)
         }
         
         start_background_job 'PlayerProxy.start', player_proxy_arguments
         
         # Wait for the player to start and catch errors
         begin
            update_match!
         rescue
            reset_to_match_entry_view 'Sorry, unable to retrieve the first match state, please start a new match or rejoin one already in progress.'
         end
      end
      replace_page_contents_with_updated_game_view
   end

   def take_action
      puts "   ACTIION: #{params[:user_poker_action]}"

      @user_poker_action = UserPokerAction.new params[:user_poker_action]
      params[:match_id] = @user_poker_action.match_id
      params[:match_slice_index] = @user_poker_action.match_slice_index
      
      start_background_job('PlayerProxy.play', match_id: @user_poker_action.match_id,
                           action: @user_poker_action.poker_action, modifier: @user_poker_action.modifier)
      
      update_game_state
   end

   # @todo Rename "game" to "match"
   def update_game_state
      begin
         update_match!
      rescue
         reset_to_match_entry_view 'Sorry, unable to update the match state, please start a new match or rejoin one already in progress.'
      else
         replace_page_contents_with_updated_game_view
      end
   end
   
   # @todo Rename "game" to "match"
   def leave_game
      redirect_to root_path, :remote => true
   end
end

