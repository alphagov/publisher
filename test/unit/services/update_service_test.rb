require 'test_helper'

class UpdateServiceTest < ActiveSupport::TestCase
  setup do
    Services.publishing_api.stubs(:put_content)
    EditionPresenterFactory.stubs(:get_presenter).returns(presenter)
  end

  context ".call" do
    should "send the rendered Edition to the publishing api" do
      Services.publishing_api.expects(:put_content).with(
        content_id,
        payload
      )

      UpdateService.call(edition)
    end
  end

  def presenter
    stub(render_for_publishing_api: payload)
  end

  def payload
    @_payload ||= stub
  end

  def edition
    @_edition ||= stub(content_id: content_id)
  end

  def content_id
    'content_id_yo'
  end
end
