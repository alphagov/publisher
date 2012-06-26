require 'test_helper'

class Admin::BaseHelperTest < ActionView::TestCase
  test "should strip govspeak and markdown when using indexable_content_with_parts" do
    edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, state: "published")
    assert_equal "Some Part Title! This is some version text. Another Part Title This is link text.", edition.indexable_content_with_parts
  end
end
