require 'test_helper'

class PublishServiceTest < ActiveSupport::TestCase
  setup do
    Services.publishing_api.stubs(:publish)
  end

  should "register edition with Rummager" do
    edition.expects(:register_with_rummager)

    PublishService.call(edition)
  end

  should "publish edition to PublishingAPI" do
    Services.publishing_api.expects(:publish).with(
      content_id,
      update_type,
      locale: language
    )

    PublishService.call(edition, update_type)
  end

  def edition
    @_edition ||= stub(
      id: 123,
      register_with_rummager: true,
      artefact: stub(
        content_id: content_id,
        language: language
      )
    )
  end

  def content_id
    'swans'
  end

  def update_type
    'ducks'
  end

  def language
    'foreign'
  end
end
