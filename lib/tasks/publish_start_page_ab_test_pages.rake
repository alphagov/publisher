namespace :start_page_ab_test_pages do
  desc "Publish choose how to sign in page"
  task publish_choose_sign_in_page: :environment do
    content_id = "f34ebcbc-4955-4f57-89bd-4d6aa7e72edf"
    params = {
      base_path: "/log-in-file-self-assessment-tax-return/choose-sign-in",
      document_type: "generic_with_external_related_links",
      locale: "en",
      public_updated_at: "2016-11-10T12:58:31.000+00:00",
      publishing_app: "publisher",
      rendering_app: "government-frontend",
      schema_name: "generic",
      update_type: "major",
      title: "Choose how to sign in",
      routes: [
        {
          path: "/log-in-file-self-assessment-tax-return/choose-sign-in",
          type: "exact"
        }
      ],
      description: "",
      details: {}
    }

    Services.publishing_api.put_content(content_id, params)
    Services.publishing_api.publish(content_id)
  end

  desc "Publish not registered page"
  task publish_not_registered_page: :environment do
    content_id = "8897173c-583a-47c7-b23f-c8624434dd1a"
    params = {
      base_path: "/log-in-file-self-assessment-tax-return/not-registered",
      document_type: "generic_with_external_related_links",
      locale: "en",
      public_updated_at: "2016-11-10T12:58:31.000+00:00",
      publishing_app: "publisher",
      rendering_app: "government-frontend",
      schema_name: "generic",
      update_type: "major",
      title: "Register for Self Assessment",
      routes: [
        {
          path: "/log-in-file-self-assessment-tax-return/not-registered",
          type: "exact"
        }
      ],
      description: "",
      details: {}
    }

    Services.publishing_api.put_content(content_id, params)
    Services.publishing_api.publish(content_id)
  end

  desc "Publish lost account details page"
  task publish_lost_account_details_page: :environment do
    content_id = "ec28dd82-8ac6-48e8-a34d-0ff00d0606b5"
    params = {
      base_path: "/log-in-file-self-assessment-tax-return/lost-account-details",
      document_type: "generic_with_external_related_links",
      locale: "en",
      public_updated_at: "2016-11-10T12:58:31.000+00:00",
      publishing_app: "publisher",
      rendering_app: "government-frontend",
      schema_name: "generic",
      update_type: "major",
      title: "Forgotten username or password",
      routes: [
        {
          path: "/log-in-file-self-assessment-tax-return/lost-account-details",
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
