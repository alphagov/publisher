Rails.application.routes.draw do
  get '/healthcheck' => 'healthcheck#check'

  resources :notes do
    put 'resolve', on: :member
  end

  get 'downtimes' => 'downtimes#index'

  resources :artefacts, only: [:new, :create, :update]

  resources :editions do
    member do
      get 'diff'
      get 'metadata'
      get 'history'
      get 'admin'
      get 'tagging', to: "editions#linking"
      get 'related_external_links' , to: "editions#linking"
      get 'unpublish'
      post 'duplicate'
      post 'update_tagging'
      post 'process_unpublish'
      patch 'update_related_external_links'
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

    resource :downtime, only: [:new, :create, :edit, :update, :destroy]
  end

  get 'reports' => 'reports#index', as: :reports
  get 'reports/progress' => 'reports#progress', as: :progress_report
  get 'reports/business_support_schemes_content' => 'reports#business_support_schemes_content', :as => :business_support_report
  get 'reports/organisation-content' => 'reports#organisation_content', :as => :organisation_content_report
  get 'reports/edition-churn' => 'reports#edition_churn', as: "edition_churn_report"
  get 'reports/content_workflow' => 'reports#content_workflow', as: "content_workflow_report"

  get 'user_search' => 'user_search#index'

  resources :publications
  root :to => 'root#index'

  # We used to nest all URLs under /admin so we now redirect that
  # in case people had bookmarks set up. Using a proc as otherwise the
  # path parameter gets escaped
  get "/admin(/*path)", to: redirect { |params, req| "/#{params[:path]}" }

  mount GovukAdminTemplate::Engine, at: "/style-guide"
end
