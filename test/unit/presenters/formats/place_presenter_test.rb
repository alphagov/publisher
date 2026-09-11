require "test_helper"

class PlacePresenterTest < ActiveSupport::TestCase
  def subject
    Formats::PlacePresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(:place_edition, panopticon_id: artefact.id)
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "place", slug: "find-food")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "place")
  end

  it_includes_last_edited_by_editor_id

  should "[:schema_name]" do
    assert_equal "place", result[:schema_name]
  end

  context "[:details]" do
    should "[:introduction]" do
      edition.update!(introduction: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:introduction]
    end

    should "[:external_related_links]" do
      link = { "url" => "https://www.foo.com", "title" => "foo" }
      external_link = ArtefactExternalLink.build(link)
      artefact.external_links = [external_link]
      artefact.save!
      expected = [
        {
          url: link["url"],
          title: link["title"],
        },
      ]

      assert_equal expected, result[:details][:external_related_links]
    end

    should "not send through nil fields" do
      edition.update!(need_to_know: nil)

      assert_not_includes result[:details].keys, :need_to_know
    end
  end

  should "[:routes]" do
    edition.update!(slug: "foo")
    expected = [
      { path: "/foo", type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end

  context ".render_for_fact_check_manager_api" do
    should "return a rendered block per field, in edit form order" do
      edition = FactoryBot.create(
        :place_edition,
        introduction: "Find your nearest office.",
        more_information: "Offices open Monday to Friday.",
        need_to_know: "You must book an appointment.",
      )
      presenter = Formats::PlacePresenter.new(edition)

      expected = {
        "introduction" => { heading: "Introduction", body: "<p>Find your nearest office.</p>" },
        "more_information" => { heading: "Further information", body: "<p>Offices open Monday to Friday.</p>" },
        "need_to_know" => { heading: "What you need to know", body: "<p>You must book an appointment.</p>" },
      }

      result = presenter.render_for_fact_check_manager_api

      assert_equal expected.keys, result.keys
      assert_equal expected, result
    end

    should "render the govspeak in each field" do
      edition = FactoryBot.create(:place_edition, need_to_know: "%You must book an appointment.%")
      presenter = Formats::PlacePresenter.new(edition)

      assert_equal(
        "<div role=\"note\" aria-label=\"Warning\" class=\"application-notice help-notice\">\n<p>You must book an appointment.</p>\n</div>",
        presenter.render_for_fact_check_manager_api["need_to_know"][:body],
      )
    end

    should "omit any blank fields" do
      edition = FactoryBot.create(:place_edition, more_information: "", need_to_know: nil)
      presenter = Formats::PlacePresenter.new(edition)

      assert_equal %w[introduction], presenter.render_for_fact_check_manager_api.keys
    end

    should "fall back to the merged body when every field is blank, as empty content is rejected" do
      edition = FactoryBot.create(:place_edition, introduction: nil, more_information: nil, need_to_know: nil)
      presenter = Formats::PlacePresenter.new(edition)

      assert_equal(
        { content: { heading: "Body", body: "<h2 class=\"edition-title\">Far far away</h2>" } },
        presenter.render_for_fact_check_manager_api,
      )
    end
  end
end
