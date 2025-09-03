# Below are the routes for madmin
namespace :adminit do
  root to: "dashboard#index"
  resources :accounts
  resources :tickets

  resources :roles, only: [:index, :show] do
    get "account_select", on: :member
    delete "account", to: "roles#remove_account", on: :member

    post "account", to: "roles#add_account", on: :member
  end
  resources :permissions, only: [:index] do
    put "/", to: "permissions#update", on: :member
  end
end
