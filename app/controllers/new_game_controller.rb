
# Third party


# Local modules
require 'application_defs'
require 'application_helper'

# Local classes
require 'match'

# Controller for the 'start a new game' view.
class NewGameController < ApplicationController
   include ApplicationDefs
   include ApplicationHelper
   
   # Presents the main 'start a new game' view.   
   def index
      # TODO move this string into a shared resource
      replace_page_contents 'new_game/index'
   end

   # Starts a new two-player limit game.
   def two_player_limit
      @match_params = two_player_limit_params params
            
      dealer_arguments = [@match_params[:match_name],
                          @match_params[:game_definition_file_name].to_s,
                          @match_params[:number_of_hands].to_s,
                          @match_params[:random_seed].to_s,
                          @match_params[:player_names].split(/\s*,?\s+/)].flatten
      
      # Initialize a match
      match = Match.create(parameters: @match_parameters)
      
      ## Start the player that represents the browser operator
      #Stalker.enqueue("Game.start", :id => match.id.to_s)
      #
      # TODO Make sure the background server is started at this point
      
      # Start the dealer

      # Wait for the dealer to start and catch errors
      
      # TODO Replace this
      #begin
      #   dealer_runner.start_dealer!(:arg => dealer_arguments)
      #rescue => unable_to_start_dealer
      #   # TODO Not sure what is the best thing to do after printing the message since I can't use an else to contain a render for some reason
      #   warn "ERROR: #{unable_to_start_dealer.message}\n"
      #   return
      #end
      #
      #log "two_player_limit: successfully started dealer"
      #
      #port_numbers = (dealer_runner.dealer_string).split(/\s+/)
      #   
      #log "two_player_limit: port_numbers: #{port_numbers}"
      #   
      #(@port_number, @opponent_port_number) = port_numbers
      #
      
      # Start bots if there are not enough human players in the match
      
      #bot_arguments = {:port_number => @opponent_port_number}

      #begin
      #   log 'two_player_limit: adding user to table'
      #   
      #   bot_user.add_user_to_table!(:arg => bot_arguments)
      #rescue => unable_to_add_bot_to_table
      #   # TODO Not sure what is the best thing to do after printing the message since I can't use an else to contain a render for some reason
      #   warn "ERROR: Unable to add bot to table: #{unable_to_add_bot_to_table.message}\n"
      #   return
      #end
      
      log 'two_player_limit: sending parameters to connect to dealer'
      
      send_parameters_to_connect_to_dealer
   end

   # Starts a new two-player no-limit game.
   def two_player_no_limit
      #send_parameters_to_connect_to_dealer
   end

   # Starts a new three-player limit game.
   def three_player_limit
      #send_parameters_to_connect_to_dealer
   end

   # Starts a new three-player no-limit game.
   def three_player_no_limit
      #send_parameters_to_connect_to_dealer
   end
end
