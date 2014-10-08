require "test_helper"

class PublishedEditionPresenterTest < ActiveSupport::TestCase
  context ".render_for_publishing_api" do
    should "create an attributes hash for the publishing api" do
      edition = FactoryGirl.create(:edition, :published)

      presenter = PublishedEditionPresenter.new(edition)

      expected_attributes_for_publishing_api_hash = {
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
        update_type: "major",
        details: {
          change_note: "",
          tags: { # Coming soon
            browse_pages: [],
            topics: [],
          }
        }
      }

      assert_equal expected_attributes_for_publishing_api_hash, presenter.render_for_publishing_api
    end

    should "consider editions with skipped fact check to be minor changes" do
      edition = FactoryGirl.create(:edition, :published)

      presenter = PublishedEditionPresenter.new(edition)

      assert_equal "major", presenter.render_for_publishing_api[:update_type]

      edition.actions.create!(request_type: Action::SKIP_FACT_CHECK)

      assert_equal "minor", presenter.render_for_publishing_api[:update_type]
    end
  end
end
