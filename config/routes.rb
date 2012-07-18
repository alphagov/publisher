Publisher::Application.routes.draw do

  namespace :admin do
    resources :notes
    resources :expectations, :except => [:edit, :update, :destroy]

    resources :editions do
      member do
        post 'duplicate'
        post 'progress'
        post 'start_work', to: 'editions#progress',
          activity: { request_type: 'start_work' }
        post 'skip_fact_check', to: 'editions#progress',
          activity: { request_type: 'skip_fact_check', comment: "Fact check skipped by request."}
      end
    end

    match 'user_search' => 'user_search#index'

    resources :publications
    match 'overview' => 'overview#index'
    root :to => 'root#index'
  end

  resources :publications, :only => :show do
    post :verify_snac, :on => :member
  end
  resources :licences, :only => :index, :defaults => { :format => 'json' }

  post "/local_transactions/verify_snac", :to => "publications#verify_snac"

  get "/local_transactions/find_by_snac", :to => "local_transactions#find_by_snac"
  get "/local_transactions/find_by_council_name", :to => "local_transactions#find_by_council_name"

  root to: redirect("/admin")
end
