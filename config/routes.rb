require 'preview_dispatcher'

Publisher::Application.routes.draw do

  namespace :admin do
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
    
    match 'google_insight' => 'seo#google_insight'
    
    root :to => 'root#index'
  end
  
  resources :audiences
  resources :publications, :only => [:show,:index]
  resources :local_transactions, :only => :show do
    member do
      get '/all(.:format)', :to => :all
      get '/:snac(.:format)', :to => :snac
      post :verify_snac
    end
  end

  match '/preview/:edition_id' => PreviewDispatcher.new, :anchor => false, :as => :preview_edition_prefix
  match '/places/*path' => PlacesFrontEnd::App
end
