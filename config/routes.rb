AcpcPokerGuiClient::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Routes for NewGame:
  match 'new_game/create' => 'new_game#create', :as => :create_new_match
  match 'new_game/two_player_no_limit' => 'new_game#two_player_no_limit', :as => :new_two_player_no_limit
  match 'new_game/three_player_limit' => 'new_game#three_player_limit', :as => :new_three_player_limit
  match 'new_game/three_player_no_limit' => 'new_game#three_player_no_limit', :as => :new_three_player_no_limit

  # @todo Fix these
  # Routes for JoinGame:
  #match 'join_game/' => 'join_game#index', :as => :join_game
  #match 'join_game/two_player_limit' => 'join_game#two_player_limit', :as => :join_two_player_limit
  #match 'join_game/two_player_no_limit' => 'join_game#two_player_no_limit', :as => :join_two_player_no_limit
  #match 'join_game/three_player_limit' => 'join_game#three_player_limit', :as => :join_three_player_limit
  #match 'join_game/three_player_no_limit' => 'join_game#three_player_no_limit', :as => :join_three_player_no_limit

  # Routes for PlayerActions
  match 'game_home' => 'player_actions#index', :as => :game_home
  match 'bet' => 'player_actions#bet', :as => :bet
  match 'check' => 'player_actions#check', :as => :check
  match 'call' => 'player_actions#call', :as => :call
  match 'fold' => 'player_actions#fold', :as => :fold
  match 'raise' => 'player_actions#raise_action', :as => :raise
  match 'update_game_state' => 'player_actions#update_game_state', :as => :update_game_state
  match 'leave_game' => 'player_actions#leave_game', :as => :leave_game


  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # Root of the site
  root :to => 'new_game#new'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
