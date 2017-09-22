Rails.application.routes.draw do
  devise_for :users
  root to: 'exchange_rates#index'

  resources :exchange_rates, only: :index
  resources :glasses, only: :index
  resources :commands, only: :index do
    collection do
      post :refresh_glasses
    end
  end
  namespace :graphs do
    resource :arbitrage, only: :show
    resources :rates, only: :index
  end
  resources :arbitrage_periods, only: [:index, :show]
  resources :arbitrage_points, only: :show
end
