
# Local classes
require File.expand_path('../communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../communication_logic/action_sender', __FILE__)
require File.expand_path('../communication_logic/matchstate_string_receiver', __FILE__)

# A bot that connects to a dealer as a proxy.
class ProxyBot
   
   # @return [MatchstateString] The current match state string.
   attr_reader :match_state_string
   
   # @return [Integer] The position relative to the dealer that is next to act.
   attr_reader :position_relative_to_dealer_next_to_act
   
   # @return [Integer] The position relative to the dealer that acted last.
   attr_reader :position_relative_to_dealer_acted_last
   
   # @return [Integer] The maximum number of hands in the current match.
   attr_reader :max_number_of_hands
   
   # @param [DealerInformation] dealer_information Information about the dealer to which this bot should connect.
   def initialize(dealer_information)
      @dealer_communicator = AcpcDealerCommunicator.new dealer_information.port_number, dealer_information.host_name
   end
   
   # @param [Symbol] action The action to be sent.
   # @param [#to_s] modifier A modifier that should be associated with the
   #  +action+ before it is sent.
   # @raise (see ActionSender#send_action)
   def send_action(action, modifier = nil)
      ActionSender.send_action @dealer_communicator, @match_state_string, action, modifier
   end
   
   # @see MatchstateStringReceiver#receive_match_state_string
   def receive_match_state_string
      # @todo Not sure if I need to keep track of this
      @last_round = @match_state_string.round if @match_state_string
      
      #@position_relative_to_dealer_acted_last = @position_relative_to_dealer_next_to_act if @position_relative_to_dealer_next_to_act
      
      @match_state_string = MatchstateStringReceiver.receive_matchstate_string @dealer_communicator
      
      #find_position_relative_to_dealer_next_to_act!
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?      
      less_than_two_active_players? || reached_showdown?
   end
   
   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?      
      #users_turn_to_act = @position_relative_to_dealer_next_to_act == @match_state_string.position_relative_to_dealer
      #
      ## Check if the match has ended
      #users_turn_to_act &= !match_ended?
      #
      #users_turn_to_act
   end
   
   private
   
   #@todo This may not work if the dealer just immediately sends the next match state after a fold and it definitely doesn't work in 3-player
   def less_than_two_active_players?
      'f' == @match_state_string.last_action
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   # @todo make this more general; this only works for two-splayer right now.
   def opponents_cards_visible?
      are_visible = 1 == @match_state_string.list_of_opponents_hole_cards.length
   end
   
   #def find_position_relative_to_dealer_next_to_act!
   #   number_of_actions_in_current_round = @match_state.number_of_actions_in_current_round
   #   first_position_in_current_round = @game_definition.first_player_position_in_each_round[round]-1
   #   
   #   @position_relative_to_dealer_next_to_act = (first_position_in_current_round + number_of_actions_in_current_round) % number_of_active_players
   #end
end
