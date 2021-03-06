Rails.application.routes.draw do
  devise_for :users
  root to: 'exchange_rates#index'

  resources :exchange_rates, only: :index
  resources :glasses, only: :index
  namespace :graphs do
    resource :arbitrage, only: :show
    resources :rates, only: :index
  end
  resources :arbitrage_periods, only: [:index, :show]
  resources :arbitrage_points, only: :show
  resources :downloads, only: [:index, :create]
  resources :stocks, only: [:index, :show, :edit, :update]
  resources :stock_currencies, only: [:edit, :update]
end
