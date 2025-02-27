require "test_helper"

class AnswerPresenterTest < ActiveSupport::TestCase
  def subject
    Formats::AnswerPresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(:answer_edition, panopticon_id: artefact.id)
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "answer")
  end

  def result
    subject.render_for_publishing_api
  end

  it_includes_last_edited_by_editor_id

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "answer")
  end

  should "[:schema_name]" do
    assert_equal "answer", result[:schema_name]
  end

  context "[:details]" do
    should "[:body]" do
      edition.update!(body: "foo")
      expected = [
        {
          content_type: "text/govspeak",
          content: "foo",
        },
      ]
      assert_equal expected, result[:details][:body]
    end

    should "[:external_related_links]" do
      link = { "url" => "https://www.foo.com", "title" => "foo" }
      artefact.external_links = [ArtefactExternalLink.build(link)]
      artefact.save!
      expected = [
        {
          url: link["url"],
          title: link["title"],
        },
      ]

      assert_equal expected, result[:details][:external_related_links]
    end
  end

  should "[:routes]" do
    edition.update!(slug: "foo")
    expected = [
      { path: "/foo", type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end

  should "[:rendering_app]" do
    assert_equal "frontend", result[:rendering_app]
  end
end
