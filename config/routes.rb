Rails.application.routes.draw do
  root "books#index"
  get "/library", to: "books#library", as: :library

  resource :session, only: %i[ new create destroy ] do
    scope module: "sessions" do
      resources :transfers, only: %i[ show update ]
    end
  end
  get "/auth/:provider/callback", to: "sessions/oauth#callback"
  get "/auth/failure", to: "sessions/oauth#failure"

  get "/home", to: "home#index", as: :home
  namespace :home do
    resources :books, only: %i[index show]
    resources :agents, only: %i[index show]
    resource :pricing, only: :show
    resource :publishing, only: :show
    resource :billing, only: :show
    resource :seller_onboarding, only: %i[show update]
    resource :stripe_connect_account, only: :create do
      post :sync
    end
    resource :settings, only: :show
  end

  resource :agents, only: :show, path: "/agents", controller: :agents do
    get :home, as: :surface_home
    get :capabilities, as: :surface_capabilities
    get :quickstart, as: :surface_quickstart
    get :help, as: :surface_help
  end

  resources :claims, only: :show, param: :token do
    post "start/:provider", action: :start, on: :member, as: :start
  end

  get "join/:join_code", to: "users#new", as: :join
  post "join/:join_code", to: "users#create"

  resource :account do
    scope module: "accounts" do
      resource :join_code, only: :create
      resource :custom_styles, only: %i[ edit update ]
    end
  end
  resources :api_keys, only: %i[ index create ] do
    member do
      patch :revoke
      patch :rotate
    end
  end

  resources :books, except: %i[ index show ] do
    resource :publication, controller: "books/publications", only: %i[ show edit update ]
    resource :purchase, controller: "books/purchases", only: :create do
      get :success
    end
    resource :bookmark, controller: "books/bookmarks", only: :show

    scope module: "books" do
      namespace :leaves do
        resources :moves, only: :create
      end

      resource :search
    end

    resources :sections
    resources :pictures
    resources :pages
  end

  get "/:id/:slug", to: "books#show", constraints: { id: /\d+/ }, as: :slugged_book
  get "/:book_id/:book_slug/:id/:slug", to: "leafables#show", constraints: { book_id: /\d+/, id: /\d+/ }, as: :slugged_leafable

  direct :book_slug do |book, options|
    route_for :slugged_book, book, book.slug, options
  end

  direct :leafable_slug do |leaf, options|
    route_for :slugged_leafable, leaf.book, leaf.book.slug, leaf, leaf.slug, options
  end

  resources :pages, only: [] do
    scope module: "pages" do
      resources :edits, only: :show
    end
  end

  resources :qr_code, only: :show
  resources :users do
    scope module: "users" do
      resource :profile
    end
  end

  direct :leafable do |leaf, options|
    route_for "book_#{leaf.leafable_name}", leaf.book, leaf, options
  end

  direct :edit_leafable do |leaf, options|
    route_for "edit_book_#{leaf.leafable_name}", leaf.book, leaf, options
  end

  namespace :action_text, path: nil do
    get "/u/*slug" => "markdown/uploads#show", as: :markdown_upload
    post "/uploads" => "markdown/uploads#create", as: :markdown_uploads
  end


  namespace :api do
    resources :agents, only: %i[ index show create ] do
      post :claim, on: :member
    end

    resources :uploads, only: %i[ create show ]

    resources :books, only: %i[ create update ] do
      member do
        patch :pricing, action: :set_pricing
        patch :publication, action: :set_publication
        put :cover, action: :upload_cover
        get :source
        post :publish, action: :publish_revision
        post :unpublish, action: :unpublish
      end

      post :chapters, action: :upsert_chapter
      post :pages, action: :upsert_page
      get :revisions, action: :revisions
      get "revisions/:revision_id", action: :show_revision
      get "revisions/:revision_id/source", action: :source_for_revision
    end
  end

  get "/.well-known/cafaye-agent.json", to: "well_known/cafaye_agents#show", as: :well_known_cafaye_agent

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
