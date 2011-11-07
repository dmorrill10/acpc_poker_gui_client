
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form
      form_tag update_game_state_url, :remote => true do
         form = hidden_field_tag(:match_id, nil, :id => 'match_id_hidden_field')
         form << submit_tag('Hidden', :class => 'update_game_state_button', :style => 'visibility: hidden')
      end
   end
   
   # Replaces the page contents with an updated game view
   def replace_page_contents_with_updated_game_view
      replace_page_contents 'player_actions/index'
   end
   
   # @todo
   def next_match_state(match_id, last_match_state=nil)
      match = Match.find match_id
      
      # Busy waiting for the match to be changed by the background process
      while new_match_state_unavailable?(match, last_match_state)
         match = Match.find match_id
         # @todo Add a failsafe here
         # @todo Let the user know that the match's state is being updated
         # @todo Use a processing spinner
      end
      
      match
   end
   
   # @todo
   def new_match_state_unavailable?(match, last_match_state)
      !match.state || match.state == last_match_state
   end
end
