Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  # Public site. Book URLs are /books/:id-:slug (id is canonical, slug optional help).
  resources :books, only: [ :show ]
  get "last_readings", to: "last_readings#index"
  get "wishlist", to: "wishlist#index"
  resources :tags, only: [ :index, :show ]
  get "calendar/:year", to: "calendar#show", as: :calendar, constraints: { year: /\d{4}/ }
  get "feed", to: "feed#index", as: :feed, defaults: { format: :xml }
  get "search", to: "search#index"

  # PWA
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker

  # Admin (Phase 1: no authentication, acts on the default user).
  namespace :admin do
    root "dashboard#index"
    resources :books do
      resources :reviews, only: %i[new create edit update destroy]
    end
    resources :tags, except: :show
    resources :series, except: :show
  end
end
