
# Local modules
require File.expand_path('../../../lib/acpc_poker_types', __FILE__)

# Helpers for controller tests.
module ControllerTestHelper
   def get_page_and_check_success(page_name)
      get page_name
      response.should be_success
   end
   def generate_match_params
      {port_number: '18791', match_name: 'default',
         game_definition_file_name: AcpcPokerTypes::GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker],
         number_of_hands: '1', random_seed: '1', player_names: 'user, p2'}
   end
end
