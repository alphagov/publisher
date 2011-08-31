require 'preview_dispatcher'

class NonAuthConstraint
  def matches?(request)
    ! request.path.match(/^\/auth/)
  end
end

Publisher::Application.routes.draw do
  # authenticate :user do
    match '/preview/:edition_id' => PreviewDispatcher.new, :anchor => false, :as => :preview_edition_prefix
  # end

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
  resources :publications, :only => [:show]
  resources :local_transactions, :only => :show do
    member do
      get '/:snac(.:format)', :to => :snac
      post :verify_snac
    end
  end

  root :to => 'root#index'
  match '/places/*path' => PlacesFrontEnd::App
  
  match "*path", :to => GuidesFrontEnd::App, :constraints => NonAuthConstraint.new
end
