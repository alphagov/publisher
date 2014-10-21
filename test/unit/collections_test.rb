require 'test_helper'
require 'support/tag_test_helpers'

describe Collections do
  include TagTestHelpers

  before do
    stub_browse_pages
  end

  describe "#grouped_mainstream_browse_pages" do
    it "returns all browse pages grouped by parent" do
      grouped_collections = Collections.grouped_mainstream_browse_pages

      assert_equal 1, grouped_collections.count

      parent_title, sub_collections = grouped_collections.first

      assert_equal 'Tax', parent_title

      assert_equal 'VAT', sub_collections[0].title
      assert_equal 'tax/vat', sub_collections[0].slug
      refute sub_collections[0].draft?

      assert_equal 'Capital Gains Tax', sub_collections[1].title
      assert_equal 'tax/capital-gains', sub_collections[1].slug
      refute sub_collections[1].draft?

      assert_equal 'RTI', sub_collections[2].title
      assert_equal 'tax/rti', sub_collections[2].slug
      assert sub_collections[2].draft?
    end
  end
end
