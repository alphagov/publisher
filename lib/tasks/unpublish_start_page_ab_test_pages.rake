namespace :start_page_ab_test_pages do
  desc "Unpublish self assessment signin pages"
  task unpublish_self_assessment_signin_pages: :environment do
    content_ids = %w(
      f34ebcbc-4955-4f57-89bd-4d6aa7e72edf
      8897173c-583a-47c7-b23f-c8624434dd1a
      ec28dd82-8ac6-48e8-a34d-0ff00d0606b5
    )

    content_ids.each do |content_id|
      Services.publishing_api.unpublish(
        content_id,
        type: "gone",
        discard_drafts: true
      )
    end
  end
end
