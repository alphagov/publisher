require 'test_helper'

class UpdateWorkerTest < ActiveSupport::TestCase
  context "#perform" do
    should "call the UpdateService" do
      edition = FactoryBot.create(:edition)
      UpdateService.expects(:call).with(edition)
      PublishService.expects(:call).never

      UpdateWorker.new.perform(edition.id)
    end

    context "when publish is true" do
      should "call the PublishService" do
        edition = FactoryBot.create(:edition)

        PublishService.expects(:call).with(edition)
        UpdateWorker.new.perform(edition.id, true)
      end
    end
  end
end
