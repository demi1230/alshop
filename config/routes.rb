Rails.application.routes.draw do
  # Devise authentication routes with custom controllers
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  # Public product browsing
  resources :products, only: [:index, :show]
  
  # Public service browsing
  resources :services, only: [:index, :show]

  # Categories
  resources :categories, only: [:index] do
    member do
      get :children, defaults: { format: :json }
    end
  end

  # Cart and cart items
  resource :cart, only: [:show] do
    delete :clear, on: :member
  end
  resources :cart_items, only: [:create, :update, :destroy]

  # Orders (requires authentication)
  resources :orders, only: [:index, :show, :create]

  # Subscriptions (requires authentication)
  resources :subscriptions, only: [:index, :create] do
    member do
      patch :cancel
    end
  end

  # Service fulfillments (staff only)
  resources :service_fulfillments, only: [:index, :show, :update]

  # Admin namespace
  namespace :admin do
    root to: 'base#index'
    get 'dashboard', to: 'dashboard#index'
    
    # Catalog Management
    resources :products do
      collection do
        patch :bulk_update
        patch :reorder
      end
      member do
        patch :toggle_active
        post :generate_combinations
        patch :update_variants
      end
    end
    
    resources :services do
      collection do
        post :bulk_action
      end
      member do
        patch :toggle_active
      end
      resources :service_config_specs, except: [:show]
      resources :subscription_plans, except: [:show]
    end
    
    resources :categories do
      collection do
        post :bulk_action
        patch :reorder
      end
      resources :category_attributes, except: [:show]
    end
    
    resources :brands do
      collection do
        post :bulk_action
      end
    end
    
    # Pricing & Discounts
    resources :pricing_rules do
      collection do
        post :bulk_action
      end
    end
    
    resources :discounts do
      member do
        patch :toggle_active
      end
    end
    
    # Orders & Fulfillment
    resources :orders, only: [:index, :show] do
      member do
        patch :mark_paid
        patch :mark_shipped
        patch :cancel
      end
    end
    
    resources :service_fulfillments, only: [:index, :show, :update] do
      member do
        patch :assign
        patch :complete
      end
    end
    
    # B2B Management
    resources :companies do
      member do
        patch :toggle_active
      end
    end
    
    resources :company_pricing_rules
    
    # User Management
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        patch :toggle_active
      end
    end
    
    # Settings
    resource :settings, only: [:show, :update]
  end

  # API namespace
  namespace :api do
    resources :products, only: [:index, :show]
    resources :categories, only: [] do
      member do
        get :children
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "products#index"
end
