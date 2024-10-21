Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"
    get "/static_pages/home"
    get "/static_pages/help"
    get "/static_pages/contact"

    get "/categories/index"
    get "/categories/show"

    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    
    get "/search", to: "search#index"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"
    devise_for :users
    as :user do
      get "signin" => "devise/sessions#new"   
      post "signin" => "devise/sessions#create" 
      delete "signout" => "devise/sessions#destroy"
    end
    resources :users do
      resources :addresses, except: :show
      resources :orders, only: %i(index order_details) do
        get 'order_details', to: 'orders#order_details', as: :order_details
        member do
          patch :cancel
        end
        resources :products, only: [] do
          resources :reviews, only: %i(new create edit update destroy)
        end
        collection do
          get :status, action: :index
        end
      end
      resources :notifications, only: [] do
        member do
          patch :mark_as_read
        end
      end
    end
    resources :categories do
      resources :products
    end
    resources :carts, only: :show do
      post "add_item", on: :collection
      member do
        post "increment_item"
        post "decrement_item"
        delete "remove_item"
      end
    end
    resources :products, only: %i(show index)
    resources :orders, only: %i(new create show) 
    namespace :admin do
      get "profile", to: "dashboard#profile", as: "profile"
      get "dashboard", to: "dashboard#index", as: "dashboard"
      resources :orders
      resources :users do
        member do
          patch :toggle_activation
        end
      end
      resources :products
      resources :categories
      resources :reviews
      require "sidekiq/web"
      mount Sidekiq::Web => "/sidekiq"
    end

  end
end
