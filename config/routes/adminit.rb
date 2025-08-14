# Below are the routes for madmin
namespace :adminit do
  root to: "dashboard#index"
  resources :accounts
end
