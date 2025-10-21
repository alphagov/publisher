require "test_helper"

class GuidePresenterTest < ActiveSupport::TestCase
  def subject
    Formats::GuidePresenter.new(edition)
  end

  def edition
    @edition ||= FactoryBot.create(:guide_edition, panopticon_id: artefact.id)
  end

  def artefact
    @artefact ||= FactoryBot.create(:artefact, kind: "guide", slug: "national-curriculum")
  end

  def add_part(num)
    Part.create(
      title: "title-#{num}",
      slug: "slug-#{num}",
      body: "body-#{num}",
      order: num,
      guide_edition: edition.editionable,
    )
  end

  def result
    subject.render_for_publishing_api
  end

  it_includes_last_edited_by_editor_id

  should "be valid against schema" do
    assert_valid_against_publisher_schema(result, "guide")
  end

  should "[:schema_name]" do
    assert_equal "guide", result[:schema_name]
  end

  context "[:details]" do
    should "[:parts]" do
      add_part(2)
      add_part(1)

      expected = [
        {
          title: "title-1",
          slug: "slug-1",
          body: [
            {
              content_type: "text/govspeak",
              content: "body-1",
            },
          ],
        },
        {
          title: "title-2",
          slug: "slug-2",
          body: [
            {
              content_type: "text/govspeak",
              content: "body-2",
            },
          ],
        },
      ]

      assert_equal expected, result[:details][:parts]
    end

    should "handle nil parts of parts" do
      Part.new(guide_edition: edition.editionable).save!(validate: false)

      expected = [{
        title: "",
        slug: "",
        body: [{
          content_type: "text/govspeak",
          content: "",
        }],
      }]

      assert_equal expected, result[:details][:parts]
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

    should "[:hide_chapter_navigation]" do
      edition.hide_chapter_navigation = true
      edition.save!(validate: false)

      assert_equal true, result[:details][:hide_chapter_navigation]
    end
  end

  should "[:routes]" do
    edition.slug = "foo"
    edition.save!(validate: false)
    expected = [
      { path: "/foo", type: "prefix" },
    ]
    assert_equal expected, result[:routes]
  end

  should "[:rendering_app]" do
    assert_equal "frontend", result[:rendering_app]
  end
end
