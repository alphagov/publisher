require 'test_helper'

class CompletedTransactionPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::CompletedTransactionPresenter.new(edition)
  end

  def edition
    @_edition ||= FactoryGirl.create(
      :completed_transaction_edition,
      :published,
      title: "Whacked all moles",
      slug: "done/good",
      panopticon_id: artefact.id,
    )
  end

  def artefact
    @_artefact ||= FactoryGirl.create(:artefact, kind: "completed_transaction")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'completed_transaction')
  end

  should "[:schema_name]" do
    assert_equal 'completed_transaction', result[:schema_name]
  end

  context "[:details]" do
    should "[:promotion]" do
      edition.presentation_toggles["promotion_choice"] = {
        'choice' => 'organ_donor',
        'url' => 'http://www.foo.com'
      }

      expected = {
        category: 'organ_donor',
        url: 'http://www.foo.com'
      }

      assert_equal expected, result[:details][:promotion]
    end

    should "no [:promotion]" do
      edition.presentation_toggles["promotion_choice"] = {
        'choice' => 'none',
        'url' => ''
      }

      assert_nil result[:details][:promotion]
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
end
