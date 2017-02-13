require 'test_helper'

class UpdateServiceTest < ActiveSupport::TestCase
  setup do
    @edition = stub(id: 123)
    PublishingAPIUpdater.stubs(:perform_async)
  end

  should "create or update draft in PublishingAPI" do
    PublishingAPIUpdater.expects(:perform_async).with('123')

    UpdateService.call(@edition)
  end
end
