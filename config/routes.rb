AcpcPokerGuiClient::Application.routes.draw do
  # Routes for MatchStart:
  match 'match_start/new' => 'match_start#new', :as => :new_match
  match 'match_start/rejoin' => 'match_start#rejoin', :as => :rejoin_match
  match 'match_start/join' => 'match_start#join', :as => :join_match

  # Routes for PlayerActions
  match 'match_home' => 'player_actions#index', :as => :match_home
  match 'update' => 'player_actions#update', as: :update
  match 'update_state' => 'player_actions#update_state', as: :update_state
  match 'update_hotkeys' => 'player_actions#update_hotkeys', :as => :update_hotkeys
  match 'leave_match' => 'player_actions#leave_match', :as => :leave_match

  # Root of the site
  root :to => 'match_start#index'
end
