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

      ScheduledPublisher.perform_at(edition.publish_at, user.id, edition.id, comment: "schedule!")

      assert_equal 1, ScheduledPublisher.jobs.size
      assert_equal edition.publish_at.to_i, ScheduledPublisher.jobs.first['at']
    end
  end

  context ".perform" do
    setup do
      stub_register_published_content
      @user = FactoryGirl.create(:user)
      @edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
    end

    should "publish the edition" do
      ScheduledPublisher.new.perform(@user.id, @edition.id, comment: "schedule!")
      assert @edition.reload.published?
    end

    should "pass on the activity details" do
      ScheduledPublisher.new.perform(@user.id, @edition.id, comment: "schedule!")
      assert_equal "schedule!", @edition.reload.actions.last[:comment]
    end

    should "update statsd counters" do
      Statsd.any_instance.expects(:decrement).with("publisher.edition.scheduled_for_publishing")
      Statsd.any_instance.expects(:increment).with("publisher.edition.published")

      ScheduledPublisher.new.perform(@user.id, @edition.id, comment: "schedule!")
    end
  end
end
