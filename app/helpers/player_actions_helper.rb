
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form(match_id)
      form_tag update_game_state_url, :remote => true do
         form = hidden_field_tag(:match_id, match_id, :id => 'match_id_hidden_field')
         form << submit_tag('Hidden', :class => 'update_game_state_button', :style => 'visibility: hidden')
      end
   end
   
   # Replaces the page contents with an updated game view
   def replace_page_contents_with_updated_game_view
      replace_page_contents 'player_actions/index'
   end
   
   # Updates the current match state.
   def update_match!
      @match = next_match_state params[:match_id]
      @match_params = {}
      @match_params[:match_id] = @match.id
   end
   
   # @todo document
   def next_match_state(previous_match_id)      
      # Busy waiting for the match to be changed by the background process
      while !(next_match_id = Match.find(previous_match_id).next_match_id)
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      
      Match.find next_match_id
   end
   
   # @todo
   def new_match_state_unavailable?(match, last_match_state)
      !match.state || match.state == last_match_state
   end
end
