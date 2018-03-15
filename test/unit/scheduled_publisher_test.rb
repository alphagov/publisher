require "test_helper"

class ScheduledPublisherTest < ActiveSupport::TestCase
  context ".enqueue" do
    setup do
      Sidekiq::Testing.fake!
    end

    teardown do
      ScheduledPublisher.jobs.clear
    end

    should "queue up an edition for publishing at the specified publish_at time" do
      FactoryBot.create(:user)
      edition = FactoryBot.create(:edition, :scheduled_for_publishing)

      ScheduledPublisher.enqueue(edition)

      assert_equal 1, ScheduledPublisher.jobs.size
      assert_equal edition.publish_at.to_i, ScheduledPublisher.jobs.first['at'].to_i
    end
  end

  context ".perform" do
    setup do
      PublishService.stubs(:call)
      @edition = FactoryBot.create(:edition, :scheduled_for_publishing, body: "some text")
    end

    should "publish the edition" do
      ScheduledPublisher.new.perform(@edition.id.to_s)
      assert @edition.reload.published?
    end

    should "call downstream publish service" do
      PublishService.expects(:call).with(@edition)
      ScheduledPublisher.new.perform(@edition.id.to_s)
    end

    should "report on edition state counts" do
      Publisher::Application.edition_state_count_reporter.expects(:report)
      ScheduledPublisher.new.perform(@edition.id.to_s)
    end
  end
end
