require "test_helper"

class PublishServiceTest < ActiveSupport::TestCase
  should "publish edition to PublishingAPI" do
    Services.publishing_api.expects(:publish).with(
      content_id,
      update_type,
      locale: language,
    )

    PublishService.call(edition, update_type)
  end

  should "set links" do
    Services.publishing_api.expects(:patch_links).with(content_id, links: { "primary_publishing_organisation" => %w[af07d5a5-df63-4ddc-9383-6a666845ebe9] })
    PublishService.call(edition, update_type)
  end

  def edition
    @edition ||= stub(
      id: 123,
      artefact: stub(
        content_id:,
        language:,
      ),
    )
  end

  def content_id
    "swans"
  end

  def update_type
    "ducks"
  end

  def language
    "foreign"
  end
end
