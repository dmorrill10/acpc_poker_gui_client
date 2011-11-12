
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form(match_id, match_slice_index)
      form_tag update_game_state_url, :remote => true do
         form = hidden_field_tag(:match_id, match_id, id: 'match_id_hidden_field')
         form << hidden_field_tag(:match_slice_index, match_slice_index, id: 'match_slice_index_hidden_field')
         form << submit_tag('Hidden', :class => 'update_game_state_button', :style => 'visibility: hidden')
      end
   end
   
   # Replaces the page contents with an updated game view
   def replace_page_contents_with_updated_game_view
      replace_page_contents 'player_actions/index'
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
      @match = Match.find @match_id
      # Busy waiting for the match to be changed by the background process
      while new_match_state_unavailable?
         @match = Match.find @match_id
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      @match.slices[@match_slice_index]
   end
   
   # @todo
   def new_match_state_unavailable?
      @match.slices.length < @match_slice_index + 1
   end
end
