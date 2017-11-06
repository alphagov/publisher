namespace :start_page_ab_test_pages do
  desc "Publish interstitial page"
  task publish_interstitial_page: :environment do
    content_id = "f34ebcbc-4955-4f57-89bd-4d6aa7e72edf"
    params = {
      base_path: "/log-in-file-self-assessment-tax-return/interstitial",
      document_type: "generic_with_external_related_links",
      locale: "en",
      public_updated_at: "2016-11-10T12:58:31.000+00:00",
      publishing_app: "publisher",
      rendering_app: "government-frontend",
      schema_name: "generic",
      update_type: "major",
      title: "Pick method",
      routes: [
        {
          path: "/log-in-file-self-assessment-tax-return/interstitial",
          type: "exact"
        }
      ],
      description: "",
      details: {}
    }

    Services.publishing_api.put_content(content_id, params)
    Services.publishing_api.publish(content_id)
  end

  desc "Publish create account page"
  task publish_create_account_page: :environment do
    content_id = "8897173c-583a-47c7-b23f-c8624434dd1a"
    params = {
      base_path: "/log-in-file-self-assessment-tax-return/create-account",
      document_type: "generic_with_external_related_links",
      locale: "en",
      public_updated_at: "2016-11-10T12:58:31.000+00:00",
      publishing_app: "publisher",
      rendering_app: "government-frontend",
      schema_name: "generic",
      update_type: "major",
      title: "Create an account",
      routes: [
        {
          path: "/log-in-file-self-assessment-tax-return/create-account",
          type: "exact"
        }
      ],
      description: "",
      details: {}
    }

    Services.publishing_api.put_content(content_id, params)
    Services.publishing_api.publish(content_id)
  end
end
