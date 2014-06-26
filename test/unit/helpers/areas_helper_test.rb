require "test_helper"

class AreasHelperTest < ActionView::TestCase
  include AreasHelper

  def test_edition_areas_json
    Area.stubs(:areas).returns([
      Area.new(id: 123, name: "London"),
      Area.new(id: 234, name: "Paris"),
      Area.new(id: 666, name: "New York")
    ])

    edition = OpenStruct.new(areas: ["123","234"])
    assert_equal ["London", "Paris"],
      JSON.parse(edition_areas_json(edition)).map { |a| a["text"] }
  end

  def test_all_regions?
    Area.stubs(:regions).returns([
      Area.new(id: 123, type: "EUR"),
      Area.new(id: 234, type: "EUR"),
    ])

    edition = OpenStruct.new(areas: ["123","234"])
    assert_equal true, all_regions?(edition)
    edition = OpenStruct.new(areas: ["123","234", "333"])
    assert_equal false, all_regions?(edition)
  end

  def test_english_regions?
    Area.stubs(:regions).returns([
      Area.new(id: 123, type: "EUR", country_name: "England"),
      Area.new(id: 234, type: "EUR", country_name: "Scotland")
    ])

    edition = OpenStruct.new(areas: ["123"])
    assert_equal true, english_regions?(edition)
    edition = OpenStruct.new(areas: ["123", "234"])
    assert_equal false, english_regions?(edition)
  end
end
