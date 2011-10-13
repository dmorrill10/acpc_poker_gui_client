require 'application_defs'
require 'application_helper'

# Controller for the 'join a game' view.
class JoinGameController < ApplicationController
   include ApplicationDefs
   include ApplicationHelper
   
   # Presents the main 'join a game' view.
   def index
      # TODO move this string into a shared resource
      replace_page_contents 'join_game/index'
   end

   # Joins a two-player limit game
   # Expects an :amount element in the params hash
   def two_player_limit
      (@port_number,
       @match_name,
       @game_definition_file_name,
       @number_of_hands,
       @random_seed,
       @list_of_player_names) = two_player_limit_params
      
      send_parameters_to_connect_to_dealer
   end
      
   # Joins a two-player no-limit game.
   def two_player_no_limit
      #send_parameters_to_connect_to_dealer
   end

   # Joins a three-player limit game.
   def three_player_limit
      #send_parameters_to_connect_to_dealer
   end

   # Joins a three-player no-limit game.
   def three_player_no_limit
      #send_parameters_to_connect_to_dealer
   end
end
