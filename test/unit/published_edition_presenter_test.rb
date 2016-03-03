require "test_helper"

class PublishedEditionPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  context ".render_for_publishing_api" do
    should "generate an attributes hash for the publishing api" do
      artefact = create(:artefact)

      edition = create(
        :edition,
        :published,
        browse_pages: ["tax/vat", "tax/capital-gains"],
        primary_topic: "oil-and-gas/wells",
        additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
        major_change: true,
        updated_at: 1.minute.ago,
        change_note: 'Test',
        version_number: 2,
        panopticon_id: artefact.id,
      )

      payload = PublishedEditionPresenter.new(edition).payload

      expected = {
        title: edition.title,
        base_path: "/#{edition.slug}",
        description: "",
        format: "placeholder",
        need_ids: [],
        public_updated_at: edition.updated_at,
        publishing_app: "publisher",
        rendering_app: "frontend",
        routes: [ { path: "/#{edition.slug}", type: "exact" }],
        redirects: [],
        details: {
          change_note: edition.change_note,
          tags: {
            browse_pages: ["tax/vat", "tax/capital-gains"],
            primary_topic: ["oil-and-gas/wells"],
            additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
            topics: ["oil-and-gas/wells", "oil-and-gas/fields", "oil-and-gas/distillation"],
          }
        },
        locale: 'en',
      }

      assert_equal expected, payload
      assert_valid_against_schema(payload, 'placeholder')
    end
  end
end
