require "test_helper"

class RepublishContentTest < ActiveSupport::TestCase
  should "send all published items to sidekiq" do
    FactoryGirl.create(:edition, state: 'draft')
    FactoryGirl.create(:edition, state: 'published')

    Sidekiq::Testing.fake! do
      RepublishContent.schedule_republishing

      assert_equal 1, PublishingAPINotifier.jobs.size
    end
  end

  should "does not error when running the sidekiq with the arguments" do
    stub_any_publishing_api_call
    edition = create(:edition, state: 'published')

    RepublishContent.schedule_republishing

    assert_publishing_api_put_content(edition.artefact.content_id)
    assert_publishing_api_publish(edition.artefact.content_id)
  end
end
