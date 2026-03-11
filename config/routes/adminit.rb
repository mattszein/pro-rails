# Below are the routes for madmin
namespace :adminit do
  root to: "application#index"
  resources :accounts
  resources :tickets do
    member do
      post :take
      post :leave
      post :finish
      post :reopen
      post :accept_reopen
      get :reject_reopen
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
end
