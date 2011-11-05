require 'spec_helper'

require File.expand_path('../../../lib/application_defs', __FILE__)

describe ApplicationHelper do
   include ApplicationDefs
   
   describe '#two_player_limit_params' do
      it 'returns a game parameter hash filled with all the necessary arguments to start a two-player limit match properly defined to defaults' do
         params = {random_seed: '1'}
         helper.two_player_limit_params(params).should be == (
            {port_number: '18791', match_name: 'default',
               game_definition_file_name: GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker],
               number_of_hands: '1', random_seed: params[:random_seed], player_names: 'user, p2'})
      end
   end
end
