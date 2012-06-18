
# System
require 'socket'

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
      Match.delete_matches_older_than(DEALER_MILLISECOND_TIMEOUT * 10**(-3))
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
      
      @match.seat ||= (rand(2) + 1).to_s
      @match.random_seed ||= lambda do
         random_float = rand
         random_int = (random_float * 10**random_float.to_s.length).to_i
         random_int.to_s
      end.call
      
      # For some reason, +REGISTERED_BOTS.key(ApplicationDefs.const_get(@match.bot))+
      #  doesn't work so I'm converting the classes in REGISTERED_BOTS to strings
      registered_bot_keys_as_strings = REGISTERED_BOTS.inject({}) do |hash, key_value|
         (key, value) = key_value
         hash[key] = value.to_s
         hash
      end
      names = ['user', registered_bot_keys_as_strings.key(@match.bot)]
      @match.player_names = (if @match.seat.to_i == 2 then names.reverse else names end).join(', ')
      
      @match.number_of_hands ||= 1
      @match.game_definition_file_name = GAME_DEFINITION_FILE_NAMES[@match.game_definition_key]
      @match.millisecond_response_timeout = DEALER_MILLISECOND_TIMEOUT
      unless @match.save
         reset_to_match_entry_view 'Sorry, unable to start the match, please try again or rejoin a match already in progress.'
      else
         dealer_arguments = [@match.match_name,
                             @match.game_definition_file_name,
                             @match.number_of_hands.to_s,
                             @match.random_seed.to_s,
                             @match.player_names.split(/\s*,?\s+/),
                             '--t_response ' + @match.millisecond_response_timeout.to_s,
                             '--t_hand ' + @match.millisecond_response_timeout.to_s,
                             '--t_per_hand ' + @match.millisecond_response_timeout.to_s].flatten
         
         start_background_job('Dealer.start', {match_id: @match.id, dealer_arguments: dealer_arguments})
         
         continue_looping_condition = lambda { |match| !match.port_numbers }
         begin
            temp_match = failsafe_while_for_match(@match.id, continue_looping_condition) {}
         rescue
            @match.delete
            reset_to_match_entry_view 'Sorry, unable to start the match, please try again or rejoin a match already in progress.'
            return
         end
         @match = temp_match
         
         port_numbers = @match.port_numbers
         
         user_port_index = @match.seat-1
         opponent_port_index = if 0 == user_port_index then 1 else 0 end
         @port_number = port_numbers[user_port_index]
         @opponent_port_number = port_numbers[opponent_port_index]
      
         # Start an opponent         
         bot_class = Object::const_get(@match.bot)
         
         # ENSURE THAT ALL REQUIRED KEY-VALUE PAIRS ARE INCLUDED IN THIS BOT
         # ARGUMENT HASH.
         bot_argument_hash = {
            port_number: @opponent_port_number,
            millisecond_response_timeout: @match.millisecond_response_timeout,
            server: Socket.gethostname,
            game_def: @match.game_definition_file_name
         }
         
         bot_start_command = bot_class.run_command bot_argument_hash
         
         opponent_arguments = {
            match_id: @match.id,
            bot_start_command: bot_start_command
         }
         
         start_background_job 'Opponent.start', opponent_arguments
         
         send_parameters_to_connect_to_dealer
      end
   end
   
   def rejoin
      match_name = params[:match_name].strip
      
      begin
         @match = Match.where(match_name: match_name).first
         raise unless @match         
         
         @port_number = @match.port_numbers[@match.seat-1]
         send_parameters_to_connect_to_dealer
      rescue
         reset_to_match_entry_view "Sorry, unable to find match \"#{match_name}\"."
      end
   end
end
