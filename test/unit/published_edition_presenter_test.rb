require "test_helper"

class PublishedEditionPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  context ".render_for_publishing_api with a published document" do
    setup do
      artefact = FactoryGirl.create(:artefact,
        content_id: "fd4b7ea6-5e95-489e-ac73-0d8710e894d8",
      )
      @edition = FactoryGirl.create(:edition, :published,
        browse_pages: ["tax/vat", "tax/capital-gains"],
        primary_topic: "oil-and-gas/wells",
        additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
        major_change: true,
        updated_at: 1.minute.ago,
        change_note: 'Test',
        version_number: 2,
        panopticon_id: artefact.id,
      )

      @presenter = PublishedEditionPresenter.new(@edition)

      @expected_attributes_for_publishing_api_hash = {
        title: @edition.title,
        base_path: "/#{@edition.slug}",
        description: "",
        format: "placeholder",
        need_ids: [],
        public_updated_at: @edition.public_updated_at,
        publishing_app: "publisher",
        rendering_app: "frontend",
        content_id: "fd4b7ea6-5e95-489e-ac73-0d8710e894d8",
        routes: [ { path: "/#{@edition.slug}", type: "exact" }],
        redirects: [],
        update_type: "major",
        details: {
          change_note: @edition.change_note,
          tags: {
            browse_pages: ["tax/vat", "tax/capital-gains"],
            primary_topic: ["oil-and-gas/wells"],
            additional_topics: ["oil-and-gas/fields", "oil-and-gas/distillation"],
            topics: ["oil-and-gas/wells", "oil-and-gas/fields", "oil-and-gas/distillation"],
          }
        },
        locale: 'en',
      }
    end

    should "create an attributes hash for the publishing api" do
      assert_equal @expected_attributes_for_publishing_api_hash, @presenter.render_for_publishing_api(republish: false)
    end

    should "create an attributes hash for the publishing api for a republish" do
      attributes_for_republish = @expected_attributes_for_publishing_api_hash.merge({
        update_type: "republish",
      })
      presented_hash = @presenter.render_for_publishing_api(republish: true)
      assert_equal attributes_for_republish, presented_hash
      assert_valid_against_schema(presented_hash, 'placeholder')
    end

    should 'create an attributes hash for a minor change' do
      @edition.update_attribute(:major_change, false)

      output = @presenter.render_for_publishing_api(republish: false)
      assert_equal 'minor', output[:update_type]
    end

    should 'always return a "major" update_type for a first edition' do
      first_edition = FactoryGirl.create(:edition, major_change: false, version_number: 1)
      presenter = PublishedEditionPresenter.new(first_edition)

      output = presenter.render_for_publishing_api(republish: false)
      assert_equal 'major', output[:update_type]
    end
  end

  context ".render_for_publishing_api with a draft document" do
    setup do
      artefact = FactoryGirl.create(:artefact,
        content_id: SecureRandom.uuid,
      )
      updated_at = 1.minute.ago
      @edition = FactoryGirl.create(
        :edition,
        state: "draft",
        updated_at: updated_at,
        panopticon_id: artefact.id,
      )
      @output = PublishedEditionPresenter.new(@edition).render_for_publishing_api
    end

    should "be valid against schema" do
      assert_valid_against_schema(@output, 'placeholder')
    end

    should 'use updated_at value if public_updated_at is nil' do
      assert_nil @edition.public_updated_at
      assert_equal @edition.updated_at, @output[:public_updated_at]
    end

    should "filter nil elements from topics" do
      assert_equal [], @output[:details][:tags][:topics]
      assert_equal [], @output[:details][:tags][:primary_topic]
    end
  end
end
