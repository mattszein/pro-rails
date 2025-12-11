Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "application#index"
  draw :adminit
  if Rails.env.development?
    mount Lookbook::Engine, at: "/lookbook"
  end

  get "dashboard" => "dashboard#index", :as => :dashboard

  namespace :support do
    resources :tickets do
      member do
        post :attach_files
      end
      resources :messages, only: [:create]
    end
  end

  namespace :settings do
    resources :appearance, only: [:index]
  end
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
