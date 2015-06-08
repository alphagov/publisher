require "test_helper"

class EditionTaggerTest < ActiveSupport::TestCase
  test "should assign tag to a single Edition" do
    edition = FactoryGirl.create(:edition)
    EditionTagger.new([{slug: edition.slug, tag: "foo"}]).run
    edition.reload

    assert_equal ["foo"], edition.browse_pages
  end
end
