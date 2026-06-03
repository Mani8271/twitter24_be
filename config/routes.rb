Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  root "home#index"
   post 'signup',     to: 'auth#signup'
  post 'signin',     to: 'auth#signin'
  post 'send_otp',   to: 'auth#send_otp'
  post 'verify_otp', to: 'auth#verify_otp'
   post 'reset_password', to: 'auth#reset_password'
   get   "/me", to: "users#me"
   put "/me", to: "users#update_me"
   put "/change_password", to: "users#change_password"
   get "/followed_businesses", to: "users#followed_businesses"
   delete "/me", to: "users#delete_account"
  
  resources :global_feeds

    scope "/onboarding" do
    post  "/step1", to: "onboarding#step1_business_details"
    post  "/step2", to: "onboarding#step2_contact_info"
    post  "/step3", to: "onboarding#step3_location"
    post  "/step4", to: "onboarding#step4_hours"
    post  "/step5", to: "onboarding#step5_documents"
    post  "/step6", to: "onboarding#step6_images"

    post  "/send_contact_otp",   to: "onboarding#send_contact_otp"
    post  "/verify_contact_otp", to: "onboarding#verify_contact_otp"

    get   "/status", to: "onboarding#status"
    get "/step1", to: "onboarding#get_step1"
    get "/step2", to: "onboarding#get_step2"
    get "/step3", to: "onboarding#get_step3"
    get "/step4", to: "onboarding#get_step4"
    get "/step5", to: "onboarding#get_step5"
    get "/step6", to: "onboarding#get_step6"
  end


  # Business upgrade requests (user-facing)
  post "/business_upgrade_requests",        to: "business_upgrade_requests#create"
  get  "/business_upgrade_requests/status", to: "business_upgrade_requests#status"

  post "/live_location", to: "live_locations#upsert"
get  "/live_location/me", to: "live_locations#me"
get  "/live_location/reach_counts", to: "live_locations#reach_counts"
  get "reach_distance/summary", to: "reach_distance#summary"
  get "businesses/:business_id/feeds", to: "business_feeds#index"


  resources :likes, only: [:create, :destroy]   # plural
  resources :comments, only: [:index, :create, :destroy]
  resource :view, only: [:create]              # singular is okay
  patch  "/businesses/online_status", to: "businesses#toggle_online"
  delete "/businesses/images/:blob_id", to: "businesses#delete_image"
  resources :businesses, only: [:index, :show, :update] do
    member do
      get :related
    end
  end
  resources :reviews, only: [:index, :create]
  post "/follow", to: "follows#create"
  resources :offers
  resources :jobs

  namespace :api do
    namespace :v1 do
      get    "subscriptions/plans",     to: "subscriptions#plans"
      post   "subscriptions/subscribe", to: "subscriptions#subscribe"
      delete "subscriptions/cancel",    to: "subscriptions#cancel"

      get  "payments/history",            to: "payments#history"
      post "payments/initiate",          to: "payments#initiate"
      get  "payments/status/:merchant_transaction_id", to: "payments#status", as: :payment_status
      post "payments/webhook",           to: "payments#webhook"
    end
  end

  scope "/legal" do
    get "/terms",                      to: "legal#terms"
    get "/privacy-policy",             to: "legal#privacy_policy"
    get "/cancellation-refund-policy", to: "legal#cancellation_refund_policy"
  end





end
