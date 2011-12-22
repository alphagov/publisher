Publisher::Application.routes.draw do

  namespace :admin do
    resources :notes
    resources :expectations, :except => [:edit, :update, :destroy]

    resources :editions do
      post :progress, :on => :member
      post :start_work, :on => :member
      post :duplicate, :on => :member
      member do
        post 'skip_fact_check'
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
