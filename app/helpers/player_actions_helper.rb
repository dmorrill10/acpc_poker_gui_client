
# Gems
require 'acpc_poker_types'
require 'acpc_poker_match_state'

# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   
   # @todo make this better
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form(match_id, match_slice_index, hand_ended=true)
      form_tag update_game_state_url, :remote => true do
         form = hidden_match_fields match_id, match_slice_index
         form << submit_tag('Proceed to the next hand', id: 'update_match_state_button', disabled: !hand_ended)
      end
   end
   
   def hidden_check_for_new_match_state_form(match_id, match_slice_index)
      form_tag check_for_new_match_state_url, remote: true do
         form = hidden_match_fields match_id, match_slice_index
         form << submit_tag('Check for new match state', id: 'check_for_new_match_state', style: 'visibility: hidden')
      end
   end
       
   def hidden_match_fields(match_id, match_slice_index)
      form = hidden_field_tag(:match_id, match_id, id: 'match_id_hidden_field')
      form << hidden_field_tag(:match_slice_index, match_slice_index, id: 'match_slice_index_hidden_field')
   end
   
   # Replaces the page contents with an updated game view
   def replace_page_contents_with_updated_game_view
      setup_match_view
      replace_page_contents 'player_actions/index'
   end
   
   # Things the view needs to know
   def setup_match_view
      # What is the match state?
      @match_state = MatchstateString.new @match_slice.state_string

      # What is the pot size?
      pot = @match_slice.pot[0]
      @pot_size = pot.inject(0) { |sum, key_value_pair| sum += key_value_pair[1] }
      
      @pot_distribution = @match_slice.pot_distribution[0]
      
      # Who are the players in this game?
      players = @match_slice.players
      
      # What are the chip balances for each player?
      @chip_balances = players.inject({}) do |balances, player|
         balances[player['name']] = player['chip_balance']
         balances
      end
      
      players.each do |player|
         player['amount_in_pot'] = pot[player['name']]
      end

      @user = players.delete_at(AcpcPokerMatchStateDefs::USERS_INDEX)
      @user['hole_cards'] = Hand.draw_cards @user['hole_cards']
      @opponents = players
      @opponents.each do |opponent|
         opponent['hole_cards'] = if opponent['hole_cards'].empty?
            # @todo need game def info to do this properly should do something like this:
            #  cards_for_each_player = (0..@game_definition.number_of_hole_cards-1).inject(Hand.new) do |hand, i|
            #     hand << Card.new
            #  end
            (0..1).inject(Hand.new) { |hand, i| hand << Card.new }
         else
            Hand.draw_cards opponent['hole_cards']
         end
      end

      # Is it the user's turn to act?
      @users_turn_to_act = @match_slice.users_turn_to_act?
      
      # Who has the dealer button?
      @player_with_the_dealer_button = @match_slice.player_turn_information['with_the_dealer_button']
      
      # Who paid blinds?
      @player_who_submitted_big_blind = @match_slice.player_turn_information['submitted_big_blind']
      @player_who_submitted_small_blind = @match_slice.player_turn_information['submitted_small_blind']

      # Who's turn is it?
      @player_whose_turn_is_next = @match_slice.player_turn_information['whose_turn_is_next']

      # What were the sequence of actions in this hand?
      player_acting_sequence = @match_slice.player_acting_sequence
      betting_sequence = @match_slice.betting_sequence
      if player_acting_sequence
         player_acting_sequence.scan(/./).each_index do |i|
            if player_acting_sequence[i].to_i == @user['seat']
               betting_sequence[i] = betting_sequence[i].capitalize
            end
         end
      end
      @action_summary = betting_sequence
      
      # Which round is it?
      @round = @match_state.round

      # What are the board cards?
      @board_cards = BoardCards.new []
      @match_state.board_cards.each_index do |i|
         @board_cards[i] = @match_state.board_cards[i]
      end

      # What is the hand number?
      @hand_number = @match_state.hand_number

      # What is the name of the match?
      @match_name = @match.parameters[:match_name]

      # What was the last action?
      @last_action = @match_state.last_action

      # Which actions are legal?
      @legal_actions = @match_slice.legal_actions

      # Which players are still active (only in multiplayer)?

      # Has the hand ended?
      @hand_ended = @match_slice.hand_ended?         
   
      # Has the match ended?
      @match_ended = @match_slice.match_ended?
   end
   
   # Updates the current match state.
   def update_match!
      @match_slice_index = params[:match_slice_index].to_i || 0
      @match_id = params[:match_id]
      @match_slice = next_match_slice!
      @match_slice_index += 1
   end
   
   # @todo document
   def next_match_slice!
      if new_match_state_available?
         @match = current_match
      end
      @match.slices[@match_slice_index]
   end
   
   # @todo
   def new_match_state?(match)
      match.slices.length > @match_slice_index
   end
   
   def new_match_state_available?
      match = current_match
      # Busy waiting for the match to be changed by the background process
      while !new_match_state? match
         match = current_match
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      true
   end
   
   def current_match
      Match.find @match_id
   end
end
