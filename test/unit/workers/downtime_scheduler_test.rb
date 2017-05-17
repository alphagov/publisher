require 'test_helper'

class DowntimeSchedulerTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.fake!
  end

  teardown do
    Sidekiq::Testing.inline!
  end

  context ".schedule_publish_and_expiry" do
    context "when the downtime display start time is in the past" do
      should "enqueue to run immediately" do
        downtime = mock_downtime(yesterday, tomorrow)
        DowntimeScheduler.schedule_publish_and_expiry(downtime)
        assert there_is_job_enqueued_to_run_immediately(DowntimeScheduler.jobs)
      end

      should "schedule a rerun for when the downtime display window ends" do
        end_time = tomorrow
        downtime = mock_downtime(yesterday, end_time)
        DowntimeScheduler.schedule_publish_and_expiry(downtime)
        assert there_is_job_enqueued_to_run_at_time(DowntimeScheduler.jobs, end_time)
      end
    end

    context "when the downtime display start time is in the future" do
      should "schedule to run at the beginning of the display window" do
        start_time = Time.zone.now + 1.week
        end_time = Time.zone.now + 2.weeks
        downtime = mock_downtime(start_time, end_time)
        DowntimeScheduler.schedule_publish_and_expiry(downtime)
        assert there_is_job_enqueued_to_run_at_time(DowntimeScheduler.jobs, start_time)
      end

      should "schedule a rerun for when the downtime display window ends" do
        start_time = Time.zone.now + 1.week
        end_time = Time.zone.now + 2.weeks
        downtime = mock_downtime(start_time, end_time)
        DowntimeScheduler.schedule_publish_and_expiry(downtime)
        assert there_is_job_enqueued_to_run_at_time(DowntimeScheduler.jobs, end_time)
      end
    end

    context "when the downtime is nil" do
      should "not schedule any jobs" do
        DowntimeScheduler.schedule_publish_and_expiry(nil)
        assert DowntimeScheduler.jobs.empty?
      end
    end
  end

  context "#perform" do
    should "call the PublishingApiWorkflowBypassPublisher with the associated artefact" do
      downtime = FactoryGirl.create(:downtime)
      artefact = downtime.artefact

      PublishingApiWorkflowBypassPublisher
        .expects(:call)
        .with(artefact)

      DowntimeScheduler.new.perform(downtime.id)
    end

    context "when the display window has ended" do
      should "remove the downtime" do
        downtime = FactoryGirl.create(:downtime)
        PublishingApiWorkflowBypassPublisher.expects(:call)

        Timecop.freeze(downtime.end_time + 1.minute) do
          assert_changes_value_from_one_to_zero(-> { Downtime.count }) do
            DowntimeScheduler.new.perform(downtime.id)
          end
        end
      end
    end

    context "when the downtime is nil" do
      should "return without doing anything" do
        PublishingApiWorkflowBypassPublisher.expects(:call).never
        DowntimeScheduler.new.perform(nil)
      end
    end
  end

  def there_is_job_enqueued_to_run_immediately(jobs)
    jobs.one? { |job| !job.has_key? 'at' }
  end

  def there_is_job_enqueued_to_run_at_time(jobs, time)
    jobs.one? { |job| job.fetch('at', -1).between?(time.to_i, time.to_i + 60) }
  end

  def assert_changes_value_from_one_to_zero(proc)
    assert_equal 1, proc.call
    yield
    assert_equal 0, proc.call
  end

  def mock_downtime(start_time, end_time)
    stub(
      id: 123,
      display_start_time: start_time,
      end_time: end_time
    )
  end

  def yesterday
    Time.zone.now - 1.day
  end

  def tomorrow
    Time.zone.now + 1.day
  end
end
