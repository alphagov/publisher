require "test_helper"

class EditionLinksPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  context ".payload" do
    should "prepare links payload for publishing with publishing-api" do
      artefact = FactoryGirl.create(:artefact)

      edition = FactoryGirl.create(
        :edition,
        :published,
        browse_pages: ["tax/vat", "tax/capital-gains"],
        primary_topic: "oil-and-gas/wells",
        additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
        panopticon_id: artefact.id,
      )

      content_ids_by_path = {
        "/browse/tax/vat" => SecureRandom.uuid,
        "/browse/tax/capital-gains" => SecureRandom.uuid,
        "/topic/oil-and-gas/wells" => SecureRandom.uuid,
        "/topic/oil-and-gas/fields" => SecureRandom.uuid,
        "/topic/oil-and-gas/distillation" => SecureRandom.uuid
      }

      publishing_api_has_lookups(content_ids_by_path)

      payload = EditionLinksPresenter.new(edition).payload

      assert_equal(
        payload[:links][:mainstream_browse_pages],
        [
          content_ids_by_path["/browse/tax/vat"],
          content_ids_by_path["/browse/tax/capital-gains"]
        ]
      )

      assert_equal(
        payload[:links][:topics],
        [
          content_ids_by_path["/topic/oil-and-gas/wells"],
          content_ids_by_path["/topic/oil-and-gas/fields"],
          content_ids_by_path["/topic/oil-and-gas/distillation"]
        ]
      )

      assert_valid_against_links_schema(payload, 'placeholder')
    end

    should "create an empty payload if there are no links" do
      artefact = FactoryGirl.create(:artefact)

      edition = FactoryGirl.create(
        :edition,
        :published,
        browse_pages: [],
        primary_topic: nil,
        additional_topics: [],
        panopticon_id: artefact.id,
      )

      payload = EditionLinksPresenter.new(edition).payload

      assert_equal(
        payload[:links][:mainstream_browse_pages],
        []
      )

      assert_equal(
        payload[:links][:topics],
        []
      )

      assert_valid_against_links_schema(payload, 'placeholder')
    end
  end
end
