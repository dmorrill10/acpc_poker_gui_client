
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
         form << submit_tag('Proceed to the next hand', :class => 'update_match_state_button', disabled: !hand_ended)
      end
   end
   
   def hidden_check_for_new_match_state_form(match_id, match_slice_index)
      form_tag check_for_new_match_state_url, remote: true do
         form = hidden_match_fields match_id, match_slice_index
         form << submit_tag('Check for new match state', class: 'check_for_new_match_state', id: 'check_for_new_match_state', style: 'visibility: hidden')
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

      # Who are the players in this game?
      players = @match_slice.players
      
      # What are the chip balances for each player?
      @chip_balances = players.inject({}) do |balances, player|
         balances[player['name']] = player['chip_balance']
         balances
      end
      
      @user = players.delete_at(AcpcPokerMatchStateDefs::USERS_INDEX)
      @user['hole_cards'] = Hand.draw_cards @user['hole_cards']
      @opponents = players
      @opponents.each do |opponent|
         opponent['hole_cards'] = Hand.draw_cards opponent['hole_cards']
      end

      # Is it the user's turn to act?
      @users_turn_to_act = @match_slice.users_turn_to_act?
      
      # Who has the dealer button?
      
      # Who paid blinds?

      # Who's turn is it?
      
      # Who was the last player to act?
      
      # What is the pot size?
      @pot_size = @match_slice.pot[0]

      # What are the stack sizes of all the players?

      # What are the user's cards?

      # What are the opponent's cards (after a showdown)?

      # What were the sequence of actions in this hand?

      # Which round is it?
      @round = @match_state.round

      # What are the board cards?
      # @todo Need the game def's number of rounds to do this properly
      @board_cards = (0..4).inject(BoardCards.new([0, 3, 1, 1])) { |board_cards, i| board_cards << Card.new }
      @match_state.board_cards.each_index do |i|
         @board_cards[i] = @match_state.board_cards[i]
      end

      # What is the hand number?
      @hand_number = @match_state.hand_number

      # What is the name of the match?
      @match_name = @match.parameters[:match_name]

      # What is the user's position relative to the dealer?
      
      # What are the list of betting actions so far in this match?
      #@betting_actions

      # What was the last action?
      @last_action = @match_state.last_action

      # Which actions are legal?

      # Which players are still active (only in multiplayer)?

      # How many hands are alloted for this match?

      # How many players are there?

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
      next_match_slice = @match.slices[@match_slice_index] 
      puts "   PlayerActionsHelper: @match_slice_index: #{@match_slice_index}, next_match_slice!: #{next_match_slice}"
      next_match_slice
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
