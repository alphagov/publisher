require "test_helper"

class ServiceSignInPublishServiceTest < ActiveSupport::TestCase
  should "publish edition to PublishingAPI" do
    update_type = nil
    Services.publishing_api.expects(:put_content).with(content_id, payload)
    Services.publishing_api.expects(:patch_links).with(content_id, links:)
    Services.publishing_api.expects(:publish).with(content_id, update_type, locale:)

    ServiceSignInPublishService.call(presenter)
  end

  def presenter
    stub(
      render_for_publishing_api: payload,
      content_id:,
      links:,
      locale:,
    )
  end

  def content_id
    "a-content-id"
  end

  def links
    { parent: %w[6a2bf66e-2313-4204-afd5-9940de5e1d66] }
  end

  def locale
    "cy"
  end

  def payload
    @payload ||= stub
  end
end
