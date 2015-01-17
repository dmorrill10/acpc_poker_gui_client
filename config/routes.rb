AcpcPokerGuiClient::Application.routes.draw do
  # Routes for MatchStart:
  match 'match_start/sign_in' => 'match_start#sign_in', :as => :sign_in
  match 'match_start/new' => 'match_start#new', :as => :new_match
  match 'match_start/rejoin' => 'match_start#rejoin', :as => :rejoin_match
  match 'match_start/join' => 'match_start#join', :as => :join_match
  match 'match_start/start_dealer_and_players' => 'match_start#start_dealer_and_players', :as => :start_dealer_and_players
  match 'match_start/start_proxy_only' => 'match_start#start_proxy_only', :as => :start_proxy_only

  match 'match_start/update_match_queue' => 'match_start#update_match_queue', :as => :update_match_queue
  match 'match_start/enqueue_exhibition_match' => 'match_start#enqueue_exhibition_match', :as => :enqueue_exhibition_match

  # Routes for PlayerActions
  match 'player_actions/match_home' => 'player_actions#index', :as => :match_home
  match 'player_actions/play_action' => 'player_actions#play_action', :as => :play_action
  match 'player_actions/update_hotkeys' => 'player_actions#update_hotkeys', :as => :update_hotkeys
  match 'player_actions/reset_hotkeys' => 'player_actions#reset_hotkeys', as: :reset_hotkeys
  match 'player_actions/leave_match' => 'player_actions#leave_match', :as => :leave_match

  # Root of the site
  root :to => 'match_start#index'

  # Constants
  match 'application/constants' => 'application#constants', :as => :application_constants
  match 'match_start/constants' => 'match_start#constants', :as => :match_start_constants
  match 'player_actions/constants' => 'player_actions#constants', :as => :player_actions_constants
  match 'table_manager/constants' => 'application#table_manager_constants', :as => :table_manager_constants
end
