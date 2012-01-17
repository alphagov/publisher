Publisher::Application.routes.draw do

  namespace :admin do
    resources :notes
    resources :expectations, :except => [:edit, :update, :destroy]
    [ :transactions,
      :places,
      :answers,
      :guides,
      :programmes,
      :local_transactions,
    ].each do |r|
      resources r do
        resources :editions, :only => [:create, :update, :destroy] do
          post :progress, :on => :member
          post :start_work, :on => :member
          member do
            post 'skip_fact_check'
          end
        end
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
