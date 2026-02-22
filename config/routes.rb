Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
   post 'signup',     to: 'auth#signup'
  post 'signin',     to: 'auth#signin'
  post 'send_otp',   to: 'auth#send_otp'
  post 'verify_otp', to: 'auth#verify_otp'
   post 'reset_password', to: 'auth#reset_password'
   get   "/me", to: "users#me"
   put "/me", to: "users#update_me"
   put "/change_password", to: "users#change_password"
   get "/followed_businesses", to: "users#followed_businesses"
  
  resources :global_feeds

    scope "/onboarding" do
    post  "/step1", to: "onboarding#step1_business_details"
    post  "/step2", to: "onboarding#step2_contact_info"
    post  "/step3", to: "onboarding#step3_location"
    post  "/step4", to: "onboarding#step4_hours"
    post  "/step5", to: "onboarding#step5_documents"
    post  "/step6", to: "onboarding#step6_images"

    get   "/status", to: "onboarding#status"
    get "/step1", to: "onboarding#get_step1"
    get "/step2", to: "onboarding#get_step2"
    get "/step3", to: "onboarding#get_step3"
    get "/step4", to: "onboarding#get_step4"
    get "/step5", to: "onboarding#get_step5"
    get "/step6", to: "onboarding#get_step6"
  end


  post "/live_location", to: "live_locations#upsert"
get  "/live_location/me", to: "live_locations#me"
get  "/live_location/reach_counts", to: "live_locations#reach_counts"
  get "reach_distance/summary", to: "reach_distance#summary"
  get "businesses/:business_id/feeds", to: "business_feeds#index"


  resources :likes, only: [:create, :destroy]   # plural
  resources :comments, only: [:index, :create, :destroy]
  resource :view, only: [:create]              # singular is okay
  resources :businesses, only: [:index, :show]
  resources :reviews, only: [:index, :create]
  post "/follow", to: "follows#create"
  resources :offers





end
