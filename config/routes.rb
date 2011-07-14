require 'guides_front_end'

Guides::Application.routes.draw do
  match '/preview/:edition_id' => GuidesFrontEnd::Preview, :anchor => false, :as => :preview_edition_prefix

  namespace :admin do
    resources :answers do
      member do
        post :progress
      end
      resources :editions
    end
    
    resources :guides do
      member do
        post :progress
      end
      resources :editions
    end
    
    root :to => 'guides#index'
  end
  
  resources :audiences
  resources :guides, :only => [:show]
end
