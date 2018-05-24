require 'test_helper'

class UpdateWorkerTest < ActiveSupport::TestCase
  context "#perform" do
    should "call the UpdateService" do
      edition = FactoryBot.create(:edition)
      UpdateService.expects(:call).with(edition)

      UpdateWorker.new.perform(edition.id)
    end
  end
end
