Rails.application.routes.draw do
  # API Documentation
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  namespace :api do
    namespace :v1 do
      resources :websites, only: [:index, :create] do
        collection do
          post :answer
        end
      end
    end
  end

  root 'websites#new'
  resources :websites, only: [:new, :create, :index]
  post 'websites/ask', to: 'websites#ask', as: :ask_website
  get 'websites/answer', to: 'websites#answer', as: :answer_website
  post 'websites/answer', to: 'websites#answer'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
