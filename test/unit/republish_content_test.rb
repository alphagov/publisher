require "test_helper"

class RepublishContentTest < ActiveSupport::TestCase
  should "send all published items to sidekiq" do
    FactoryGirl.create(:edition, state: 'draft')
    FactoryGirl.create(:edition, state: 'published')

    Sidekiq::Testing.fake! do
      RepublishContent.schedule_republishing

      assert_equal 1, PublishingApiPublisher.jobs.size
    end
  end

  should "does not error when running the sidekiq with the arguments" do
    request_1 = stub_request(:put, %r[#{Plek.find('publishing-api')}/*])
    request_2 = stub_request(:post, %r[#{Plek.find('publishing-api')}/*])
    FactoryGirl.create(:edition, state: 'published')

    RepublishContent.schedule_republishing

    assert_requested(request_1)
    assert_requested(request_2)
  end
end
