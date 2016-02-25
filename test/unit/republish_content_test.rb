require "test_helper"
require "securerandom"

class RepublishContentTest < ActiveSupport::TestCase
  setup do
    draft_edition = FactoryGirl.create(:edition, state: 'draft')
    draft_edition.artefact.update_attributes(content_id: SecureRandom.uuid)

    @published_edition = FactoryGirl.create(:edition, state: 'published')
    @published_edition.artefact.update_attributes(content_id: SecureRandom.uuid)

    # Because we have an after_save hook on the editions,
    # a PUT is sent when creating these which is later
    # picked up by the assert_requested calls.
    #
    # Reset all request history and sidekiq queues so the assertions are checking
    # the behaviour of the republisher.
    WebMock.reset!
    Sidekiq::Worker.clear_all
  end

  should "send all published items to sidekiq" do
    Sidekiq::Testing.fake! do
      RepublishContent.schedule_republishing

      assert_equal 1, PublishingAPIRepublisher.jobs.size
    end
  end

  should "perform the sub-jobs of updating and publishing synchronously" do
    Sidekiq::Testing.fake! do
      RepublishContent.schedule_republishing

      assert_equal 0, PublishingAPIPublisher.jobs.size
      assert_equal 0, PublishingAPIUpdater.jobs.size
    end
  end

  should "sends the content as a PUT and a POST for the publish" do
    request_1 = stub_request(:put, "#{Plek.find('publishing-api')}/v2/content/#{@published_edition.artefact.content_id}")
    request_2 = stub_request(:post, "#{Plek.find('publishing-api')}/v2/content/#{@published_edition.artefact.content_id}/publish")

    RepublishContent.schedule_republishing

    assert_requested(request_1)
    assert_requested(request_2)
  end
end
