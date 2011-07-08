require 'guides_front_end'

Guides::Application.routes.draw do
  match '/preview/:edition_id' => GuidesFrontEnd, :anchor => false

  namespace :admin do
    resources :guides do
      resources :editions
    end
    
    
    root :to => 'guides#index'
  end
end
