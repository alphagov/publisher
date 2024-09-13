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

  get "downtimes" => "downtimes#index"

  resources :artefacts, only: %i[new create update]

  constraints FeatureConstraint.new("design_system_edit") do
    resources :editions, only: %i[show index]
  end

  get "editions/:id" => "legacy_editions#show"

  resources :editions, controller: "legacy_editions" do
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

    resource :downtime, only: %i[new create edit update destroy]
    get "downtime" => "downtimes#destroy", as: :destroy_downtime
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
  constraints FeatureConstraint.new("design_system_publications_filter") do
    root to: "root#index"
  end

  # The below "as: nil" is required to avoid a name clash with the constrained route, above, which causes an error
  root to: "legacy_root#index", as: nil

  # We used to nest all URLs under /admin so we now redirect that
  # in case people had bookmarks set up. Using a proc as otherwise the
  # path parameter gets escaped
  get "/admin(/*path)", to: redirect { |params, _req| "/#{params[:path]}" }

  get "/govuk-sitemap.xml" => "sitemap#index"

  get "/homepage/popular-links" => "homepage#show", as: "show_popular_links"
  post "/homepage/popular-links/create" => "homepage#create", as: "create_popular_links"
  get "/homepage/popular-links/:id" => "homepage#edit", as: "edit_popular_links"
  patch "/homepage/popular-links/:id" => "homepage#update", as: "update_popular_links"
  post "/homepage/popular-links/:id/publish" => "homepage#publish", as: "publish_popular_links"

  delete "/homepage/popular-links/:id" => "homepage#destroy", as: "delete_popular_links"
  get "homepage/popular-links/:id/confirm-destroy" => "homepage#confirm_destroy", as: "confirm_destroy_popular_links"

  mount GovukAdminTemplate::Engine, at: "/style-guide"
  mount Flipflop::Engine => "/flipflop"
  mount GovukPublishingComponents::Engine, at: "/component-guide"
end
