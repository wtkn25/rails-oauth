Rails.application.routes.draw do
  root 'home#index'

  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'log_out', to: 'sessions#destroy', as: 'log_out'

  get "calendar/index", to:"calendar#index"
  get "oauth2callback", to:"calendar#callback"

  resources :sessions, only: %i[create destroy]
end