Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "competitions#show"

  resources :competitions, only: :show, param: :slug do
    member do
      get :annual
      get :relegation
    end
    resources :stages, only: :show, param: :slug
  end

  resources :teams, only: %i[index show], param: :slug
end
