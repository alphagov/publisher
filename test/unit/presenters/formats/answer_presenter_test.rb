require 'test_helper'

class AnswerPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::AnswerPresenter.new(edition)
  end

  def edition
    @_edition ||= FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)
  end

  def artefact
    @_artefact ||= FactoryGirl.create(:artefact, kind: "answer")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'answer')
  end

  should "[:schema_name]" do
    assert_equal 'answer', result[:schema_name]
  end

  context "[:details]" do
    should "[:body]" do
      edition.update_attribute(:body, 'foo')
      expected = [
        {
          content_type: 'text/govspeak',
          content: 'foo'
        }
      ]
      assert_equal expected, result[:details][:body]
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
      { path: '/foo.json', type: 'exact' }
    ]
    assert_equal expected, result[:routes]
  end
end
