# config/routes.rb
require "sidekiq/web"

Rails.application.routes.draw do
  root "charges#index"

  mount Sidekiq::Web => "/sidekiq"

  resources :charges, only: [ :index, :new, :create, :show ] do
    member do
      post :process_charge
    end
  end

  namespace :api do
    resources :charges, only: [ :index, :show, :create ] do
      member do
        post :process_charge
      end
    end
  end
end
