require 'integration_test_helper'

class TaggingToCollectionsTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_collections
  end

  test "Tagging to browse pages" do
    edition = FactoryGirl.create(:guide_edition)

    visit edition_path(edition)

    select 'Tax: VAT', from: 'Browse pages'
    select 'Tax: RTI (draft)', from: 'Browse pages'

    save_edition

    edition.reload

    assert_equal ['tax/vat', 'tax/rti'], edition.browse_pages
  end

  test "Tagging to topics" do
    edition = FactoryGirl.create(:guide_edition)

    visit edition_path(edition)

    select 'Oil and Gas: Wells', from: 'Primary topic'

    select 'Oil and Gas: Fields', from: 'Additional topics'
    select 'Oil and Gas: Distillation (draft)', from: 'Additional topics'

    save_edition

    edition.reload

    assert_equal 'oil-and-gas/wells', edition.primary_topic
    assert_equal ['oil-and-gas/fields', 'oil-and-gas/distillation'], edition.additional_topics
  end
end
