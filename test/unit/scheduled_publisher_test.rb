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

      ScheduledPublisher.perform_at(edition.publish_at, edition.id)

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
      ScheduledPublisher.new.perform(@edition.id)
      assert @edition.reload.published?
    end

    should "update statsd counters" do
      Statsd.any_instance.expects(:decrement).with("publisher.edition.scheduled_for_publishing")
      Statsd.any_instance.expects(:increment).with("publisher.edition.published")

      ScheduledPublisher.new.perform(@edition.id)
    end
  end
end
