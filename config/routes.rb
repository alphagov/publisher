require 'guides_front_end'

Guides::Application.routes.draw do
  match '/preview/:edition_id' => GuidesFrontEnd, :anchor => false, :as => :preview_edition_prefix

  namespace :admin do
    resources :guides do
      member do
        post :progress
      end
      resources :editions
    end
    
    root :to => 'guides#index'
  end
  
  resources :audiences
end
