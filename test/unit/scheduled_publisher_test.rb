require "test_helper"

class ScheduledPublisherTest < ActiveSupport::TestCase
  context ".perform_at" do
    setup do
      Sidekiq::Testing.fake!
    end

    teardown do
      ScheduledPublisher.jobs.clear
    end

    should "queue up an edition for publishing at the specified publish_at time" do
      user = FactoryGirl.create(:user)
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

      ScheduledPublisher.perform_at(edition.publish_at, edition.id.to_s)

      assert_equal 1, ScheduledPublisher.jobs.size
      assert_equal edition.publish_at.to_i, ScheduledPublisher.jobs.first['at']
    end
  end

  context ".perform" do
    setup do
      stub_register_published_content
      @edition = FactoryGirl.create(:edition, :scheduled_for_publishing, body: "some text")
    end

    should "publish the edition" do
      ScheduledPublisher.new.perform(@edition.id.to_s)
      assert @edition.reload.published?
    end

    should "report on edition state counts" do
      StateCountReporter.any_instance.expects(:report)
      ScheduledPublisher.new.perform(@edition.id.to_s)
    end
  end
end
