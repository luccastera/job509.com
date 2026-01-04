Rails.application.routes.draw do
  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # ============================================
  # User Authentication (Devise with custom paths)
  # ============================================
  devise_for :users, skip: [:sessions, :registrations, :passwords]

  # Custom Devise routes - must be in devise_scope for devise_mapping
  devise_scope :user do
    # Session routes (login/logout)
    get "/login", to: "sessions#new", as: :new_user_session
    post "/login", to: "sessions#create", as: :user_session
    delete "/logout", to: "sessions#destroy", as: :destroy_user_session

    # Registration routes (signup)
    get "/signup", to: "registrations#new", as: :new_user_registration
    post "/signup", to: "registrations#create", as: :user_registration
    get "/emp_signup", to: "registrations#new_employer", as: :new_employer_registration
    post "/emp_signup", to: "registrations#create_employer"

    # Password reset
    get "/users/forgot_password", to: "passwords#new", as: :new_user_password
    post "/users/forgot_password", to: "passwords#create", as: :user_password
    get "/users/reset_password/:reset_password_token", to: "passwords#edit", as: :edit_user_password
    patch "/users/reset_password", to: "passwords#update"
  end

  # User profile management
  resources :users, only: [:show, :edit, :update] do
    member do
      get :change_password
      patch :save_password
    end
  end

  # ============================================
  # Root and Static Pages
  # ============================================
  root "jobs#index"

  get "/about", to: "pages#about", as: :about
  get "/faq", to: "pages#faq", as: :faq
  get "/contact", to: "pages#contact", as: :contact
  get "/advertise", to: "pages#advertise", as: :advertise

  # ============================================
  # Jobs
  # ============================================
  resources :jobs do
    member do
      get :apply
      post :submit_application
    end
    collection do
      get :search
      get :live_search
      get :filter
      get :myjobs  # Job seeker's applications
      get :employer  # Employer's posted jobs
      get :applications  # Employer views applicants
    end
  end

  # ============================================
  # Resume
  # ============================================
  resource :resume, only: [:show, :edit, :update] do
    member do
      get :preview
      get :pdf
    end
    resources :educations, only: [:create, :update, :destroy]
    resources :work_experiences, only: [:create, :update, :destroy]
    resources :skills, only: [:create, :update, :destroy]
    resources :language_skills, only: [:create, :update, :destroy]
    resources :referrals, only: [:create, :update, :destroy]
  end

  # Resume sharing via token
  get "/r/:token", to: "share#show", as: :share_resume

  # ============================================
  # Applications
  # ============================================
  resources :applics, only: [:index, :show, :destroy] do
    member do
      patch :star
      patch :unstar
      patch :hide
      patch :unhide
      get :cover_letter
      get :print
    end
  end

  # ============================================
  # Events
  # ============================================
  resources :events, only: [:index, :show] do
    member do
      get :signup
      post :register
    end
  end

  # ============================================
  # Payments
  # ============================================
  post "/payments/create", to: "payments#create", as: :payment_create
  get "/payments/confirm", to: "payments#confirm", as: :payment_confirm
  post "/payments/process", to: "payments#process_payment", as: :payment_process
  get "/payments/success", to: "payments#success", as: :payment_success
  get "/payments/cancel", to: "payments#cancel", as: :payment_cancel

  # ============================================
  # API Endpoints (JSON)
  # ============================================
  namespace :api do
    resources :jobs, only: [:index, :show]
    resources :companies, only: [:index]
    resources :schools, only: [:index]
    resources :sectors, only: [:index]
    resources :cities, only: [:index]
  end

  # Legacy JSON endpoints (for backwards compatibility)
  get "/jobs.json", to: "api/jobs#index", defaults: { format: :json }
  get "/companies.json", to: "api/companies#index", defaults: { format: :json }
  get "/schools.json", to: "api/schools#index", defaults: { format: :json }

  # ============================================
  # Sitemap & Feed
  # ============================================
  get "/sitemap.xml", to: "sitemap#index", defaults: { format: :xml }
  get "/feed", to: "feed#index", defaults: { format: :rss }

  # ============================================
  # Admin Panel (Lakay namespace)
  # ============================================
  namespace :lakay do
    root to: "dashboard#index"

    # Admin authentication
    get "/login", to: "sessions#new", as: :login
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy", as: :logout

    # Dashboard & Stats
    get "/stats", to: "dashboard#stats"
    get "/accounting", to: "dashboard#accounting"
    get "/language_stats", to: "dashboard#language_stats"
    get "/email_lists", to: "dashboard#email_lists"

    # Job Management
    resources :jobs do
      member do
        patch :approve
        patch :reject
      end
      collection do
        get :approvals
      end
    end

    # Job Seeker Management
    resources :job_seekers do
      collection do
        get :search
        get :search_by_keyword
        post :bulk_sms
      end
      member do
        patch :recommend
        patch :unrecommend
        get :pdf
        post :comment
        post :login_as
        post :add_tag
        delete :remove_tag
        post :add_to_list
        delete :remove_from_list
      end
    end

    # Employer Management
    resources :employers do
      member do
        patch :convert  # Convert employer to job seeker
      end
    end

    # Applications
    resources :applics, only: [:index, :show, :destroy] do
      member do
        patch :star
        patch :unstar
      end
    end

    # Events Management
    resources :events do
      member do
        get :attendees
      end
    end
    resources :attendees, only: [:show, :edit, :update, :destroy]

    # Coupons
    resources :coupons

    # Tags
    resources :tags do
      member do
        post :add_user
        delete :remove_user
      end
    end

    # Lists (user groups)
    resources :lists do
      member do
        post :add_user
        delete :remove_user
      end
    end

    # Administrators (super admin only)
    resources :administrators

    # Featured Recruiters
    resources :featured_recruiters
  end
end
