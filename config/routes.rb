require 'guides_front_end'

Guides::Application.routes.draw do
  authenticate :user do
    match '/preview/:edition_id' => GuidesFrontEnd::Preview, :anchor => false, :as => :preview_edition_prefix
  end

  namespace :admin do
    resources :transactions do
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
    
    root :to => 'guides#index'
  end
  
  resources :audiences
  resources :guides, :only => [:show]
  # match '/:path(/:part)', :to => GuidesFrontEnd::App, :constraints => {:path => /[^(auth)]/}
end
