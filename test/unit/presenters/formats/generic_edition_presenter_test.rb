require "test_helper"

class GenericEditionPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  context ".render_for_publishing_api with a published document" do
    setup do
      artefact = FactoryGirl.create(:artefact)

      expected_external_related_links = [
        { title: "GOVUK", url: "https://www.gov.uk" },
        { title: "GOVUK", url: "https://www.gov.uk" },
      ]
      artefact.external_links = expected_external_related_links

      @edition = FactoryGirl.create(:video_edition, :published,
        major_change: true,
        updated_at: DateTime.new(2017, 2, 06, 17, 36, 58).in_time_zone,
        change_note: 'Test',
        version_number: 2,
        panopticon_id: artefact.id,
                                   )

      @presenter = Formats::GenericEditionPresenter.new(@edition)

      @expected_attributes_for_publishing_api_hash = {
        title: @edition.title,
        base_path: "/#{@edition.slug}",
        description: "",
        schema_name: "generic_with_external_related_links",
        document_type: "answer",
        need_ids: [],
        public_updated_at: '2017-02-06T17:36:58.000+00:00',
        publishing_app: "publisher",
        rendering_app: "frontend",
        routes: [
          { path: "/#{@edition.slug}", type: "prefix" },
          { path: "/#{@edition.slug}.json", type: "exact" }
        ],
        redirects: [],
        update_type: "major",
        change_note: @edition.change_note,
        details: {
          external_related_links: expected_external_related_links,
        },
        locale: 'en',
      }
    end

    should "create an attributes hash for the publishing api" do
      assert_equal @expected_attributes_for_publishing_api_hash, @presenter.render_for_publishing_api(republish: false)
    end

    should "create an attributes hash for the publishing api for a republish" do
      attributes_for_republish = @expected_attributes_for_publishing_api_hash.merge(update_type: "republish",)
      presented_hash = @presenter.render_for_publishing_api(republish: true)
      assert_equal attributes_for_republish, presented_hash
      assert_valid_against_schema(presented_hash, 'generic_with_external_related_links')
    end

    should 'create an attributes hash for a minor change' do
      @edition.update_attribute(:major_change, false)

      output = @presenter.render_for_publishing_api(republish: false)
      assert_equal 'minor', output[:update_type]
    end

    should 'always return a "major" update_type for a first edition' do
      first_edition = FactoryGirl.create(:edition, major_change: false, version_number: 1)
      presenter = Formats::GenericEditionPresenter.new(first_edition)

      output = presenter.render_for_publishing_api(republish: false)
      assert_equal 'major', output[:update_type]
    end
  end

  context ".render_for_publishing_api with a draft document" do
    setup do
      artefact = FactoryGirl.create(
        :artefact,
        content_id: SecureRandom.uuid,
        language: 'cy',
      )
      updated_at = DateTime.new(2017, 2, 06, 17, 36, 58).in_time_zone
      @edition = FactoryGirl.create(
        :transaction_edition,
        state: "draft",
        updated_at: updated_at,
        panopticon_id: artefact.id,
      )
      @output = Formats::GenericEditionPresenter.new(@edition).render_for_publishing_api
    end

    should "be valid against schema" do
      assert_valid_against_schema(@output, 'generic_with_external_related_links')
    end

    should 'use updated_at value if public_updated_at is nil' do
      assert_nil @edition.public_updated_at
      assert_equal @edition.updated_at, @output[:public_updated_at]
    end

    should 'choose locale based on the artefact language' do
      assert_equal 'cy', @output[:locale]
    end

    should "have a exact route type for both path and json path" do
      exact_routes = [
        { path: "/#{@edition.slug}", type: "exact" },
        { path: "/#{@edition.slug}.json", type: "exact" }
      ]

      assert_equal @output[:routes], exact_routes
    end
  end
end
