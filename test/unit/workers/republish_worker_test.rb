require 'test_helper'

class RepublishWorkerTest < ActiveSupport::TestCase
  context "#perform" do
    should "call the RepublishService" do
      edition = FactoryBot.create(:edition)
      RepublishService.expects(:call).with(edition)

      RepublishWorker.new.perform(edition.id)
    end
  end
end
