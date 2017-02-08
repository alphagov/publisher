require 'test_helper'

class PublishServiceTest < ActiveSupport::TestCase
  setup do
    @edition = stub(id: 123, register_with_rummager: true)
    PublishingAPIPublisher.stubs(:perform_async)
    PublishingAPIUpdater.stubs(:perform_async)
  end

  should "register edition with Rummager" do
    @edition.expects(:register_with_rummager)

    PublishService.call(@edition)
  end

  should "publish edition to PublishingAPI" do
    PublishingAPIPublisher.expects(:perform_async).with('123')

    PublishService.call(@edition)
  end

  should "create new draft in PublishingAPI" do
    PublishingAPIUpdater.expects(:perform_async).with('123')

    PublishService.call(@edition)
  end
end
