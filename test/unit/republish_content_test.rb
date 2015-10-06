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
end
