require 'test_helper'

class PublishWorkerTest < ActiveSupport::TestCase
  context "#perform" do
    should "call the PublishService" do
      edition = FactoryBot.create(:edition)
      update_type = 'foo'
      PublishService.expects(:call).with(edition, update_type)

      PublishWorker.new.perform(edition.id, update_type)
    end
  end
end
