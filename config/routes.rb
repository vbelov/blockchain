Rails.application.routes.draw do
  root to: 'exchange_rates#index'

  resources :exchange_rates, only: :index
end
