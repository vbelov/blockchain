Rails.application.routes.draw do
  root to: 'exchange_rates#index'

  resources :exchange_rates, only: :index
  resources :glasses, only: :index
  resources :commands, only: :index do
    collection do
      post :refresh_glasses
    end
  end
  resources :graphs, only: :index
end
