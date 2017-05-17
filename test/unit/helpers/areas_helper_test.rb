require "test_helper"

class AreasHelperTest < ActionView::TestCase
  include AreasHelper

  def test_all_regions?
    Area.stubs(:regions).returns(
      [
        Area.new(
          slug: "london",
          type: "EUR",
          codes: {
            "gss" => "E15000007",
          },
        ),
        Area.new(
          slug: "north-east",
          type: "EUR",
          codes: {
            "gss" => "E15000001",
          },
        ),
      ]
    )

    edition = OpenStruct.new(
      area_gss_codes: %w(E15000007 E15000001),
    )
    assert_equal true, all_regions?(edition)

    edition = OpenStruct.new(
      area_gss_codes: %w(E15000007 E15000001 J99999999),
    )
    assert_equal false, all_regions?(edition)
  end

  def test_english_regions?
    Area.stubs(:regions).returns(
      [
        Area.new(
          slug: "yorkshire-and-the-humber",
          type: "EUR",
          country_name: "England",
          codes: {
            "gss" => "E15000003",
          },
        ),
        Area.new(
          slug: "scotland",
          type: "EUR",
          country_name: "Scotland",
          codes: {
            "gss" => "S15000001",
          },
        ),
      ]
    )

    edition = OpenStruct.new(
      area_gss_codes: ["E15000003"],
    )
    assert_equal true, english_regions?(edition)

    edition = OpenStruct.new(
      area_gss_codes: %w(E15000003 S15000001),
    )
    assert_equal false, english_regions?(edition)
  end
end
