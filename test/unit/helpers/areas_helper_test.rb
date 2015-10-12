require "test_helper"

class AreasHelperTest < ActionView::TestCase
  include AreasHelper

  def test_all_regions?
    Area.stubs(:regions).returns([
      Area.new(slug: "london", type: "EUR"),
      Area.new(slug: "north-east", type: "EUR"),
    ])

    edition = OpenStruct.new(areas: ["london","north-east"])
    assert_equal true, all_regions?(edition)
    edition = OpenStruct.new(areas: ["london","north-east", "jersey"])
    assert_equal false, all_regions?(edition)
  end

  def test_english_regions?
    Area.stubs(:regions).returns([
      Area.new(slug: "yorkshire-and-the-humber", type: "EUR", country_name: "England"),
      Area.new(slug: "scotland", type: "EUR", country_name: "Scotland")
    ])

    edition = OpenStruct.new(areas: ["yorkshire-and-the-humber"])
    assert_equal true, english_regions?(edition)
    edition = OpenStruct.new(areas: ["yorkshire-and-the-humber", "scotland"])
    assert_equal false, english_regions?(edition)
  end
end
