
# Helpers for +PlayerActions+ controller and views.
module PlayerActionsHelper
   # Places a hidden form in a view to allow AJAX to update the game's state dynamically
   def hidden_update_state_form
      form_tag update_game_state_url, :remote => true do
         submit_tag('Hidden', :class => 'update_game_state_button', :style => 'visibility: hidden')
      end
   end
   
   def close_dealer!
      puts 'close_dealer!'
         
      dealer_runner = MiddleMan.worker :dealer_runner
         
      begin
         puts "close_dealer!: dealer runner was just closed: #{dealer_runner.close!}"
         
         puts 'close_dealer!: immediately after dealer_runner.close! in begin'
      
      rescue => exception
         #TODO Handle error
         warn "ERROR: #{exception.message}\n"
      end
         
      puts 'close_dealer!: after dealer_runner.close!'
   end
   
   def replace_page_contents_with_updated_game_view
      replace_page_contents 'player_actions/index'
   end
end
