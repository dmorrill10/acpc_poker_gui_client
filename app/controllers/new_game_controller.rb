
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
   include NewGameHelper
   
   # Presents the main 'start a new game' view.   
   def new
      @match = Match.new
      respond_to do |format|
         format.html {}
         format.js do
            replace_page_contents NEW_MATCH_PARTIAL
         end
      end
   end

   # Creates a new match.
   # @todo turn this into a create method and get the game definition from the view
   def create
      @match = Match.new params[:match]
      # @todo not sure what the maximum random seed should be
      @match.random_seed = rand(100) unless @match.random_seed
      # @todo make this variable depending on the participants
      @match.player_names = 'user, testing_ruby_bot'
      # @todo Move this default to the view
      @match.number_of_hands = 1 unless @match.number_of_hands
      @match.game_definition_file_name = GAME_DEFINITION_FILE_NAMES[@match.game_definition_key]
      unless @match.save
         flash[:notice] = 'Ah! The match did not save, please retry.'
         redirect_to root_path, :remote => true
      else
         dealer_arguments = [@match.match_name,
                             @match.game_definition_file_name,
                             @match.number_of_hands.to_s,
                             @match.random_seed.to_s,
                             @match.player_names.split(/\s*,?\s+/)].flatten
         
         # @todo Make sure the background server is started at this point      
         Stalker.enqueue('Dealer.start', :match_id => @match.id, :dealer_arguments => dealer_arguments)
         
         # Busy waiting for the match to be changed by the background process
         # @todo Add a failsafe here
         while !@match.port_numbers
            @match = Match.find(@match.id)
            
            # Tell the user that the dealer is starting up
            # @todo Use a processing spinner            
            flash[:notice] = 'The dealer is starting...'
            puts flash[:notice]
         end
         
         port_numbers = @match.port_numbers
         flash[:notice] = 'Port numbers: ' + port_numbers.to_s
         
         puts flash[:notice]
         
         # @todo Need to randomize this?
         @port_number = port_numbers[0]
         @opponent_port_number = port_numbers[1]
      
         # @todo Start bots if there are not enough human players in the match
      
         # Start an opponent
         # @todo Make this better, with customization from the browser
         opponent_arguments = {match_id: @match.id,
            host_name: 'localhost', port_number: @opponent_port_number,
            game_definition_file_name: @match.game_definition_file_name}
         
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
