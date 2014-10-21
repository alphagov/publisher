require 'integration_test_helper'

class TaggingToCollectionsTest < JavascriptIntegrationTest

  test "Tagging to browse pages" do
    setup_users
    stub_browse_pages

    edition = FactoryGirl.create(:guide_edition)

    visit edition_path(edition)

    select 'Tax: VAT', from: 'Browse pages'
    select 'Tax: RTI (draft)', from: 'Browse pages'

    save_edition

    edition.reload

    assert_equal ['tax/vat', 'tax/rti'], edition.browse_pages
  end
end
