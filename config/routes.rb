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
          activity: { request_type: 'receive_fact_check', comment: "Fact check skipped by request."}
      end
    end

    resources :publications
    match 'overview' => 'overview#index'
    root :to => 'root#index'
  end

  resources :publications, :only => :show
  resources :local_transactions, :only => :show do
    member do
      get '/all(.:format)', :to => :all
      get '/:snac(.:format)', :to => :snac
      post :verify_snac
    end
  end
end
