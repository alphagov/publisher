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
    @_artefact ||= FactoryGirl.create(:artefact, kind: "completed_transaction", slug: "done/artefact")
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

  should "match the schema for allowed valies in `promotion_choice`" do
    # NOTE: We don't do a full equality test here because otherwise we can
    # get locked into failing tests when we try to add or remove a value
    # On CI jenkins will use the production releases when testing against the
    # schema which won't have the changes; and we can't publish the schema
    # because it'll test against the production publisher which won't have
    # been changed.  A subset test will allow us to have some confidence
    # that we're not out of sync. We have to remember to remove values from
    # publisher and deploy them before we remove them from content schemas
    allowed_values = GovukSchemas::Schema.find(publisher_schema: 'completed_transaction')['definitions']['details']['properties']['promotion']['properties']['category']['enum']
    extra_values_in_presenter = subject.class::PROMOTIONS - allowed_values
    assert extra_values_in_presenter.empty?, "CompletedTransactionPresenter allows values for promotion that the schema does not.\nPresenter allows: #{subject.class::PROMOTIONS.sort.inspect}\nSchema allows:    #{allowed_values.sort.inspect}\nDiff:             #{extra_values_in_presenter.sort.inspect}"
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
