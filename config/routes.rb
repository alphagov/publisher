Guides::Application.routes.draw do
  namespace :admin do
    resources :guides do
      resources :editions
    end
    
    
    root :to => 'guides#index'
  end
end
