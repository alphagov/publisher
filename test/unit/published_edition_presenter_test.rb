require "test_helper"

class PublishedEditionPresenterTest < ActiveSupport::TestCase
  context ".render_for_publishing_api" do
    setup do
      edition = FactoryGirl.create(:edition, :published,
        browse_pages: ["tax/vat", "tax/capital-gains"],
        primary_topic: "oil-and-gas/wells",
        additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"]
      )

      @presenter = PublishedEditionPresenter.new(edition)

      @expected_attributes_for_publishing_api_hash = {
        title: edition.title,
        base_path: "/#{edition.slug}",
        description: edition.overview,
        format: "placeholder",
        need_ids: [],
        public_updated_at: edition.updated_at,
        publishing_app: "publisher",
        rendering_app: "frontend",
        routes: [ { path: "/#{edition.slug}", type: "exact" }],
        redirects: [],
        update_type: "minor",
        details: {
          change_note: nil,
          tags: {
            browse_pages: ["tax/vat", "tax/capital-gains"],
            primary_topic: ["oil-and-gas/wells"],
            additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
            topics: ["oil-and-gas/wells", "oil-and-gas/fields", "oil-and-gas/distillation"],
          }
        }
      }
    end

    should "create an attributes hash for the publishing api" do
      assert_equal @expected_attributes_for_publishing_api_hash, @presenter.render_for_publishing_api(republish: false)
    end

    should "create an attributes hash for the publishing api for a republish" do
      attributes_for_republish = @expected_attributes_for_publishing_api_hash.merge({
        update_type: "republish",
      })
      assert_equal attributes_for_republish, @presenter.render_for_publishing_api(republish: true)
    end
  end
end
