AcpcPokerGuiClient::Application.routes.draw do
  # Routes for NewGame:
  match 'new_game/create' => 'new_game#create', :as => :create_new_match
  match 'new_game/rejoin' => 'new_game#rejoin', :as => :rejoin_match

  # Routes for PlayerActions
  match 'game_home' => 'player_actions#index', :as => :game_home
  match 'take_action' => 'player_actions#take_action', :as => :take_action
  match 'update_game_state' => 'player_actions#update_game_state', as: :update_game_state
  match 'leave_game' => 'player_actions#leave_game', :as => :leave_game

  # Root of the site
  root :to => 'new_game#new'
end
