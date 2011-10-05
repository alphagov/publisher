Publisher::Application.routes.draw do

  namespace :admin do
    resources :notes
    resources :expectations, :except => [:edit, :update, :destroy]
    
    resources :transactions do
      post :progress, :on => :member
      resources :editions
    end

    resources :places do
      post :progress, :on => :member
      resources :editions
    end

    resources :answers do
      post :progress, :on => :member
      resources :editions
    end

    resources :guides do
      post :progress, :on => :member
      resources :editions
    end

    resources :programmes do
      post :progress, :on => :member
      resources :editions
    end

    resources :local_transactions do
      post :progress, :on => :member
      resources :editions
    end

    resources :publications
    match 'overview' => 'overview#index'

    root :to => 'root#index'
  end

  resources :publications, :only => [:show,:index]
  resources :local_transactions, :only => :show do
    member do
      get '/all(.:format)', :to => :all
      get '/:snac(.:format)', :to => :snac
      post :verify_snac
    end
  end
end
