require 'integration_test_helper'

class TaggingToCollectionsTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_collections
  end

  test "Tagging to browse pages" do
    edition = FactoryGirl.create(:guide_edition)

    visit edition_path(edition)

    selectize ['Tax: VAT', 'Tax: RTI (draft)'], 'Mainstream browse pages'

    save_edition_and_assert_success
    edition.reload

    assert_equal ['tax/vat', 'tax/rti'], edition.browse_pages
  end

  test "Tagging to topics" do
    edition = FactoryGirl.create(:guide_edition)

    visit edition_path(edition)

    select 'Oil and Gas: Wells', from: 'Primary topic'
    select 'Oil and Gas: Fields', from: 'Additional topics'
    select 'Oil and Gas: Distillation (draft)', from: 'Additional topics'

    save_edition_and_assert_success
    edition.reload

    assert_equal 'oil-and-gas/wells', edition.primary_topic
    assert_equal ['oil-and-gas/fields', 'oil-and-gas/distillation'], edition.additional_topics
  end

  test "Mistagging primary and additional topics with the same tag" do
    edition = FactoryGirl.create(:guide_edition)
    visit edition_path(edition)

    select 'Oil and Gas: Wells', from: 'Primary topic'
    select 'Oil and Gas: Wells', from: 'Additional topics'
    select 'Oil and Gas: Distillation (draft)', from: 'Additional topics'

    save_edition_and_assert_error

    assert page.has_css?('#edition_additional_topics_input.has-error')
    assert page.has_content?("can't have the primary topic set as an additional topic")
  end
end
