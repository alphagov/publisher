require 'test_helper'

class UpdateWorkerTest < ActiveSupport::TestCase
  context "#perform" do
    should "call the UpdateService" do
      edition = FactoryBot.create(:edition)
      update_type = 'foo'
      UpdateService.expects(:call).with(edition, update_type)

      UpdateWorker.new.perform(edition.id, update_type)
    end
  end
end
