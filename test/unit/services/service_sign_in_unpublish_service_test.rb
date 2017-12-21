require 'test_helper'

class ServiceSignInUnpublishServiceTest < ActiveSupport::TestCase
  setup do
    Services.publishing_api.stubs(:unpublish)
    Services.publishing_api.stubs(:get_content).returns(content_item)
  end

  should "unpublish a content item with type 'gone'" do
    Services.publishing_api.expects(:unpublish).with(
      content_id,
      type: "gone",
      locale: locale,
      discard_drafts: true,
    )

    ServiceSignInUnpublishService.call(content_id, locale)
  end

  def content_id
    "a-content-id"
  end

  def locale
    "cy"
  end

  def content_item
    {
      "locale" => locale,
    }
  end
end
