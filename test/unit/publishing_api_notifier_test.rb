require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class PublishingAPINotifierTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  setup do
    stub_register_published_content
  end

  context ".perform(edition_id)" do
    should "sends the content to the publishing-api" do
      edition = create_edition

      PublishingAPINotifier.new.perform(edition.id)

      assert_publishing_api_put_content(edition.artefact.content_id)
      assert_publishing_api_publish(edition.artefact.content_id)
    end

    should "allow update_type to be set" do
      edition = create_edition

      PublishingAPINotifier.new.perform(edition.id, "republish")

      assert_publishing_api_publish(edition.artefact.content_id, update_type: "republish")
    end

    should "should be minor by default" do
      edition = create_edition(major_change: false, version_number: 321)

      PublishingAPINotifier.new.perform(edition.id)

      assert_publishing_api_publish(edition.artefact.content_id, update_type: "minor")
    end

    should "should be major for major changes" do
      edition = create_edition(major_change: true, version_number: 321)

      PublishingAPINotifier.new.perform(edition.id)

      assert_publishing_api_publish(edition.artefact.content_id, update_type: "major")
    end

    should "should be major for new versions" do
      edition = create_edition(major_change: false, version_number: 1)

      PublishingAPINotifier.new.perform(edition.id)

      assert_publishing_api_publish(edition.artefact.content_id, update_type: "major")
    end
  end

  def create_edition(attrs = {})
    artefact = create(:artefact)

    edition = create(:edition, :published, {
      major_change: true,
      change_note: 'Test',
      panopticon_id: artefact.id,
    }.merge(attrs))
  end
end
