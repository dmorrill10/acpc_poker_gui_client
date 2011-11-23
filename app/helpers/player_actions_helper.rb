
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form(match_id, match_slice_index)
      form_tag update_game_state_url, :remote => true do
         form = hidden_match_fields
         form << submit_tag('Update match state', :class => 'update_match_state_button')
      end
   end
   
   def check_for_new_match_state
      form_tag check_for_new_match_state_url, remote: true do
         form = hidden_match_fields
         form << submit_tag('Check for new match state', class: 'check_for_new_match_state', id: 'check_for_new_match_state', style: 'visibility: hidden')
      end
   end
       
   def hidden_match_fields
      form = hidden_field_tag(:match_id, match_id, id: 'match_id_hidden_field')
      form << hidden_field_tag(:match_slice_index, match_slice_index, id: 'match_slice_index_hidden_field')
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
      new_match_state_available?
      @match.slices[@match_slice_index]
   end
   
   # @todo
   def new_match_state?
      @match.slices.length < @match_slice_index + 1
   end
   
   def new_match_state_available?
      @match = Match.find @match_id
      # Busy waiting for the match to be changed by the background process
      while !new_match_state?
         @match = Match.find @match_id
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      true
   end
end
