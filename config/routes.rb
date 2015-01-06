Publisher::Application.routes.draw do
  get '/healthcheck' => 'healthcheck#check'

  namespace :api do
    post 'reindex-topic-editions/*slug', to: 'search#reindex_topic_editions', as: 'reindex_topic_editions'
  end

  resources :notes do
    put 'resolve', on: :member
  end

  resources :editions do
    member do
      get 'diff'
      get 'metadata'
      get 'history'
      get 'admin'
      post 'duplicate'
      post 'progress'
      put 'review'
      post 'skip_fact_check', to: 'editions#progress',
        edition: {
          activity: {
            request_type: 'skip_fact_check',
            comment: "Fact check skipped by request."
            }
          }
    end
  end

  match 'reports' => 'reports#index', as: :reports
  match 'reports/progress' => 'reports#progress', as: :progress_report
  get 'reports/business_support_schemes_content' => 'reports#business_support_schemes_content', :as => :business_support_report

  get 'areas' => 'editions#areas'

  match 'user_search' => 'user_search#index'

  resources :publications
  root :to => 'root#index'

  # We used to nest all URLs under /admin so we now redirect that
  # in case people had bookmarks set up. Using a proc as otherwise the
  # path parameter gets escaped
  get "/admin(/*path)", to: redirect { |params, req| "/#{params[:path]}" }

  mount GovukAdminTemplate::Engine, at: "/style-guide"
end
