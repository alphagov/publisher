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
end
