Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Allow GET requests for sign out (in addition to DELEE which is already built in in devise_for:users) as we want to get back to the home page after signing out
  devise_scope :user do
   get "/users/sign_out", to: "devise/sessions#destroy"
  end


  resources :workout_plans do
    resources :chats, only: [:show, :create] do
      post 'revise_plan', on: :member
      post 'apply_revision', on: :member
      resources :ai_messages, only: [:create]
    end

    resources :workout_exercises, except: [:index, :show]

    resources :workouts, only: [:index, :new, :create, :show] do
      resources :workout_logs, only: [:index, :new, :create]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
