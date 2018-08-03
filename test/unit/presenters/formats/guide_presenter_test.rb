require 'test_helper'

class GuidePresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::GuidePresenter.new(edition)
  end

  def edition
    @_edition ||= FactoryBot.create(:guide_edition, panopticon_id: artefact.id)
  end

  def artefact
    @_artefact ||= FactoryBot.create(:artefact, kind: "guide", slug: "national-curriculum")
  end

  def add_part(num)
    Part.create(
      title: "title-#{num}",
      slug: "slug-#{num}",
      body: "body-#{num}",
      hide_chapter_navigation: true,
      order: num,
      guide_edition: edition
    )
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'guide')
  end

  should "[:schema_name]" do
    assert_equal 'guide', result[:schema_name]
  end

  context "[:details]" do
    should "[:parts]" do
      add_part(2)
      add_part(1)

      expected = [
        {
          title: 'title-1',
          slug: 'slug-1',
          body: [
            {
              content_type: 'text/govspeak',
              content: 'body-1'
            }
          ],
          hide_chapter_navigation: true
        },
        {
          title: 'title-2',
          slug: 'slug-2',
          body: [
            {
              content_type: 'text/govspeak',
              content: 'body-2'
            }
          ],
          hide_chapter_navigation: true
        }
      ]

      assert_equal expected, result[:details][:parts]
    end

    should "handle nil parts of parts" do
      Part.create(guide_edition: edition)

      expected = [{
        title: "",
        slug: "",
        body: [{
          content_type: 'text/govspeak',
          content: ""
        }],
        hide_chapter_navigation: nil
      }]

      assert_equal expected, result[:details][:parts]
    end

    should "[:external_related_links]" do
      link = { 'url' => 'www.foo.com', 'title' => 'foo' }
      artefact.update_attribute(:external_links, [link])
      expected = [
        {
          url: link['url'],
          title: link['title']
        }
      ]

      assert_equal expected, result[:details][:external_related_links]
    end
  end

  should "[:routes]" do
    edition.update_attribute(:slug, 'foo')
    expected = [
      { path: '/foo', type: 'prefix' },
    ]
    assert_equal expected, result[:routes]
  end

  should "[:rendering_app]" do
    assert_equal "government-frontend", result[:rendering_app]
  end
end
