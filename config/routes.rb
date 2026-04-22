Rails.application.routes.draw do
  get "registrations/new"
  get "registrations/create"
  root "pages#home"

  get "dashboard", to: "pages#dashboard"

  resources :registrations, only: [:new, :create]
  resource :session
  resources :passwords, param: :token

  resources :squads do
    resources :squad_memberships, only: [:create, :destroy]
  end
  
  resources :rooms, only: [:new, :create, :show, :update] do
    member do
      patch :start
      patch :word 
      get :game
    end
    resources :room_memberships, only: [:create]
  end
  get 'rooms/join/:code', to: 'rooms#join', as: 'join_room_by_code'
  
  resources :games, only: [:index, :show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
