Publisher::Application.routes.draw do

  resources :notes
  resources :expectations, :except => [:edit, :update, :destroy]

  resources :editions do
    member do
      post 'duplicate'
      post 'progress'
      post 'start_work', to: 'editions#progress',
        activity: { request_type: 'start_work' }
      post 'skip_fact_check', to: 'editions#progress',
        activity: { request_type: 'skip_fact_check', comment: "Fact check skipped by request."}
    end
  end

  match 'reports' => 'reports#index', as: :reports
  match 'reports/progress' => 'reports#progress', as: :progress_report
  get 'reports/business_support_schemes_content' => 'reports#business_support_schemes_content', :as => :business_support_report

  match 'user_search' => 'user_search#index'

  resources :publications
  root :to => 'root#index'
end
