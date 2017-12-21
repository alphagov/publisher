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

  should "unpublish a content item with type 'redirect'" do
    Services.publishing_api.expects(:unpublish).with(
      content_id,
      locale: locale,
      type: "redirect",
      discard_drafts: true,
      redirects: [
        {
          path: base_path,
          type: "prefix",
          destination: redirect_path
        }
      ]
    )

    ServiceSignInUnpublishService.call(
      content_id,
      locale,
      redirect_path: redirect_path
    )
  end

  def content_id
    "a-content-id"
  end

  def locale
    "cy"
  end

  def redirect_path
    "/alternative/path"
  end

  def base_path
    "/path/sign-in"
  end

  def content_item
    {
      "locale" => locale,
      "base_path" => base_path,
    }
  end
end
