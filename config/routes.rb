# Having a long routes file is not a style violation
Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::Mongoid,
    GovukHealthcheck::SidekiqRedis,
  )

  get "/healthcheck/scheduled-publishing", to: "healthcheck#scheduled_publishing"

  resources :notes do
    put "resolve", on: :member
  end

  constraints FeatureConstraint.new("design_system_downtime_index_page") do
    get "downtimes" => "downtimes#index"
  end
  get "downtimes" => "legacy_downtimes#index"

  resources :artefacts, only: %i[new create update]

  resources :editions do
    member do
      get "diff"
      get "metadata"
      get "history"
      get "admin"
      get "tagging", to: "editions#linking"
      get "related_external_links", to: "editions#linking"
      get "unpublish"
      get "diagram"
      post "duplicate"
      post "update_tagging"
      post "process_unpublish"
      patch "update_related_external_links"
      post "progress"
      put "review"
      post "skip_fact_check",
           to: "editions#progress",
           edition: {
             activity: {
               request_type: "skip_fact_check",
               comment: "Fact check skipped by request.",
             },
           }
    end

    constraints FeatureConstraint.new("design_system_downtime_new") do
      resource :downtime, only: %i[new create]
    end
    constraints FeatureConstraint.new("design_system_downtime_edit") do
      resource :downtime, only: %i[edit update]
    end
    resource :downtime, only: %i[new create edit update destroy], controller: "legacy_downtimes"
  end

  get "reports" => "reports#index", as: :reports
  get "reports/progress" => "reports#progress", as: :progress_report
  get "reports/organisation-content" => "reports#organisation_content", :as => :organisation_content_report
  get "reports/edition-churn" => "reports#edition_churn", as: "edition_churn_report"
  get "reports/all-edition-churn" => "reports#all_edition_churn", as: "all_edition_churn_report"
  get "reports/content-workflow" => "reports#content_workflow", as: "content_workflow_report"
  get "reports/all-content-workflow" => "reports#all_content_workflow", as: "all_content_workflow_report"
  get "reports/all-urls" => "reports#all_urls", as: "all_urls_report"

  get "user_search" => "user_search#index"

  resources :link_check_reports, only: %i[create show]

  post "/link-checker-api-callback" => "link_checker_api#callback", as: "link_checker_api_callback"
  get "api/lookup-by-base-path", to: "publishing_api_proxy#lookup_by_base_path"

  resources :publications
  root to: "root#index"

  # We used to nest all URLs under /admin so we now redirect that
  # in case people had bookmarks set up. Using a proc as otherwise the
  # path parameter gets escaped
  get "/admin(/*path)", to: redirect { |params, _req| "/#{params[:path]}" }

  get "/govuk-sitemap.xml" => "sitemap#index"

  mount GovukAdminTemplate::Engine, at: "/style-guide"
  mount Flipflop::Engine => "/flipflop"
end
