# Having a long routes file is not a style violation
Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
  )

  get "/healthcheck/scheduled-publishing", to: "healthcheck#scheduled_publishing"

  resources :legacy_notes do
    put "resolve", on: :member
  end

  resources :notes do
    put "resolve", on: :member
  end

  get "downtimes" => "downtimes#index"

  resources :artefacts, only: %i[new create update]

  constraints NewDesignSystemConstraint.new do
    resources :editions do
      member do
        get "send_to_fact_check_page"
        post "send_to_fact_check"
        get "resend_fact_check_email_page"
        patch "resend_fact_check_email"
        get "approve_fact_check_page"
        post "approve_fact_check"
        get "request_amendments_page"
        post "request_amendments"
        get "send_to_2i_page"
        post "send_to_2i"
        get "no_changes_needed_page"
        post "no_changes_needed"
        get "skip_review_page"
        post "skip_review"
        get "send_to_publish_page"
        post "send_to_publish"
        get "schedule_page"
        post "schedule"
        get "cancel_scheduled_publishing_page"
        post "cancel_scheduled_publishing"
        get "metadata"
        get "history"
        get "history/add_edition_note", to: "editions#add_edition_note", as: "history/add_edition_note"
        get "history/update_important_note", to: "editions#update_important_note", as: "history/update_important_note"
        get "admin"
        get "diff"
        post "duplicate"
        get "related_external_links"
        patch "update_related_external_links"
        get "tagging", to: "editions#tagging"
        post "update_tagging"
        get "tagging_mainstream_browse_page"
        get "tagging_related_content_page"
        get "tagging_reorder_related_content_page"
        get "tagging_organisations_page"
        get "tagging_breadcrumb_page"
        get "tagging_remove_breadcrumb_page"
        get "unpublish"
        get "unpublish/confirm-unpublish", to: "editions#confirm_unpublish", as: "confirm_unpublish"
        post "process_unpublish"
        get "admin/confirm-destroy", to: "editions#confirm_destroy", as: "confirm_destroy"
        delete "admin/delete-edition", to: "editions#destroy", as: "admin_delete"
        post "progress"
        get "edit_assignee"
        patch "update_assignee"
        get "edit_reviewer"
        patch "update_reviewer"
        post "skip_fact_check",
             to: "editions#progress",
             edition: {
               activity: {
                 request_type: "skip_fact_check",
                 comment: "Fact check skipped by request.",
               },
             }
        get "guide_add_new_chapter_page"
        post "guide_add_new_chapter"
      end
    end
  end

  get "editions/:id" => "legacy_editions#show"

  resources :editions, controller: "legacy_editions" do
    member do
      get "diff"
      get "metadata"
      get "history"
      get "admin"
      get "tagging", to: "legacy_editions#linking"
      get "related_external_links", to: "legacy_editions#linking"
      get "unpublish"
      get "diagram"
      post "duplicate"
      post "update_tagging"
      post "process_unpublish"
      patch "update_related_external_links"
      post "progress"
      put "review"
      post "skip_fact_check",
           to: "legacy_editions#progress",
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

  get "by-content-id/:content_id" => "content_item#by_content_id"

  mount GovukAdminTemplate::Engine, at: "/style-guide"
  mount Flipflop::Engine => "/flipflop"
  mount GovukPublishingComponents::Engine, at: "/component-guide"
end
