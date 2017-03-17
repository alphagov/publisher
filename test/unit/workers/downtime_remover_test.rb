require 'test_helper'

class DowntimeRemoverTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.fake!
  end

  teardown do
    Sidekiq::Testing.inline!
  end

  def downtime
    @_downtime ||= stub(artefact: artefact, destroy: nil)
  end

  def artefact
    @_artefact ||= stub(id: 123)
  end

  context ".destroy_immediately" do
    should "destroy the Downtime" do
      downtime.expects(:destroy)
      DowntimeRemover.destroy_immediately(downtime)
    end

    should "enqueues to run immediately" do
      DowntimeRemover.destroy_immediately(downtime)
      assert DowntimeRemover.jobs.size == 1
    end

    context "when the Downtime is nil" do
      should "return without enqueueing a job" do
        DowntimeRemover.destroy_immediately(nil)
        assert DowntimeRemover.jobs.size == 0
      end
    end
  end

  context "#perform" do
    should "call the PublishingApiWorkflowBypassPublisher with the given artefact" do
      Artefact.stubs(:find_by).with(id: '123').returns(artefact)
      PublishingApiWorkflowBypassPublisher.expects(:call).with(artefact)
      DowntimeRemover.new.perform('123')
    end
  end
end
