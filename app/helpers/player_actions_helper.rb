
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form
      form_tag update_game_state_url, :remote => true do
         submit_tag('Hidden', :class => 'update_game_state_button', :style => 'visibility: hidden')
      end
   end
   
   # Replaces the page contents with an updated game view
   def replace_page_contents_with_updated_game_view
      replace_page_contents 'player_actions/index'
   end
end
