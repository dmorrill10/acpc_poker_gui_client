
# Third party
require 'stalker'

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
   # @todo turn this into a create method and get the game definition from the view
   def two_player_limit
      @match_params = two_player_limit_params params
      
      # Initialize a match
      # @todo Can this be made into a function to be used by this controller, the join a game controller, and the player proxy?
      match = Match.new(parameters: @match_params)
      unless match.save
         flash[:notice] = 'Ah! The match did not save, please retry.'
         redirect_to new_game_path, :remote => true
      else
         dealer_arguments = [@match_params[:match_name],
                             @match_params[:game_definition_file_name].to_s,
                             '2',#@match_params[:number_of_hands],
                             @match_params[:random_seed],
                             @match_params[:player_names].split(/\s*,?\s+/)].flatten
         
         @match_params[:match_id] = match.id
         id = @match_params[:match_id]
         
         # @todo Make sure the background server is started at this point      
         Stalker.enqueue('Dealer.start', :match_id => id, :dealer_arguments => dealer_arguments)
         
         # Busy waiting for the match to be changed by the background process
         # @todo Add a failsafe here
         while !match.port_numbers
            match = Match.find(id)
            
            # Tell the user that the dealer is starting up
            # @todo Use a processing spinner            
            flash[:notice] = 'The dealer is starting...'
            puts flash[:notice]
         end
         
         port_numbers = match.port_numbers
         flash[:notice] = 'Port numbers: ' + port_numbers.to_s
         
         puts flash[:notice]
         
         # @todo Need to randomize this?
         @match_params[:port_number] = port_numbers[0]
         @opponent_port_number = port_numbers[1]
      
         # @todo Start bots if there are not enough human players in the match
      
         # Start an opponent
         # @todo Make this better, with customization from the browser
         opponent_arguments = {match_id: @match_params[:match_id],
            host_name: 'localhost', port_number: @opponent_port_number,
            game_definition_file_name: @match_params[:game_definition_file_name]}
         
         Stalker.enqueue('Opponent.start', opponent_arguments)      
      
         send_parameters_to_connect_to_dealer
      end
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
