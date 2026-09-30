# Below are the routes for madmin
namespace :adminit do
  root to: "dashboards#index"
  resources :accounts do
    get :search, on: :collection
  end
  resources :tickets do
    member do
      post :take
      post :leave
      post :finish
      post :reopen
      post :accept_reopen
      get :reject_reopen, action: :new_reject_reopen
      post :reject_reopen
    end
    resources :notes, only: [:create], controller: "tickets/notes"
  end
  resources :announcements do
    post :schedule, on: :member
    post :unschedule, on: :member
  end

  resources :roles, only: [:index, :show] do
    get "account_select", on: :member
    delete "account", to: "roles#remove_account", on: :member
    post "account", to: "roles#add_account", on: :member
  end
  resources :permissions, only: [:index] do
    put "/", to: "permissions#update", on: :member
  end

  resources :feature_flags, only: [:index, :show] do
    member do
      get :audience_select
      post :attach_audience
      delete :detach_audience
      get :account_select
      post :add_account
      delete :remove_account
    end
  end

  # No :destroy — audiences are archived, never deleted.
  resources :audiences, except: [:destroy] do
    member do
      patch :archive
      patch :unarchive
    end
  end

  namespace :dashboard do
    get "widgets/:key",
      to: "/adminit/dashboards#widget",
      as: :widget
    get "accounts/:id/summary",
      to: "/adminit/dashboard/accounts#summary",
      as: :account_summary
  end
end
