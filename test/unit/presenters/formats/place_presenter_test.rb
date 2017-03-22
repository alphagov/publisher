require 'test_helper'

class PlacePresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::PlacePresenter.new(edition)
  end

  def edition
    @_edition ||= FactoryGirl.create(:place_edition, panopticon_id: artefact.id)
  end

  def artefact
    @_artefact ||= FactoryGirl.create(:artefact, kind: "place", slug: "find-food")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'place')
  end

  should "[:schema_name]" do
    assert_equal 'place', result[:schema_name]
  end

  context "[:details]" do
    should "[:introduction]" do
      edition.update_attribute(:introduction, 'foo')
      expected = [
        {
          content_type: 'text/govspeak',
          content: 'foo'
        }
      ]
      assert_equal expected, result[:details][:introduction]
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

    should "not send through nil fields" do
      edition.update_attribute(:need_to_know, nil)

      refute_includes result[:details].keys, :need_to_know
    end
  end

  should "[:routes]" do
    edition.update_attribute(:slug, 'foo')
    expected = [
      { path: '/foo', type: 'prefix' },
    ]
    assert_equal expected, result[:routes]
  end
end
