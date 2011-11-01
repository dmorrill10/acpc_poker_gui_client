
# Local classes
require File.expand_path('../communication_logic/acpc_dealer_communicator', __FILE__)
require File.expand_path('../communication_logic/action_sender', __FILE__)
require File.expand_path('../communication_logic/matchstate_string_receiver', __FILE__)

# A bot that connects to a dealer as a proxy.
class ProxyBot
   
   # @return [MatchstateString] The current match state string.
   attr_reader :match_state_string
   
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
   
   # @return [MatchState] 
   def update_match_state!()
      # @todo Not sure if I need to keep track of this
      @last_round = @match_state_string.round if @match_state_string
      @match_state_string = MatchstateStringReceiver.receive_matchstate_string @dealer_communicator
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?      
      less_than_two_active_players? || reached_showdown?
   end
   
   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?      
      true
      #users_turn_to_act = @position_relative_to_dealer_next_to_act == users_position
      #
      ## Check if the match has ended
      #users_turn_to_act &= !match_ended?
      #
      #users_turn_to_act
   end
   
   private
   
   #@todo This may not work if the dealer just immediately sends the next match state after a fold
   def less_than_two_active_players?
      'f' == @match_state_string.last_action
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   def opponents_cards_visible?
      are_visible = !((@match_state_string.list_of_opponents_hole_cards.reject { |hole_card_set| hole_card_set.empty? }).empty?)
   end
end
