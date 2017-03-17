require 'test_helper'

class RepublishServiceTest < ActiveSupport::TestCase
  setup do
    UpdateService.stubs(:call)
    PublishService.stubs(:call)
  end

  context ".call" do
    should "call the UpdateService with the provided edition" do
      UpdateService.expects(:call).with(edition, 'republish')
      RepublishService.call(edition)
    end

    should "call the PublishService with the provided edition" do
      PublishService.expects(:call).with(edition, 'republish')
      RepublishService.call(edition)
    end
  end

  def edition
    @_edition ||= stub
  end
end
