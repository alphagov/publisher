require "test_helper"

class LinkablesTest < ActiveSupport::TestCase
  setup do
    stub_linkables
  end

  test "returns sorted browse pages" do
    assert_equal(
      { "Benefits" => [
          ["Benefits / Benefits and financial support for families (draft)", "CONTENT-ID-FAMILIES"],
          ["Benefits / Benefits and financial support if you're caring for someone (draft)", "CONTENT-ID-HELP-FOR-CARERS"],
          ["Benefits / Benefits and financial support if you're disabled or have a health condition (draft)", "CONTENT-ID-DISABILITY"],
        ],
        "Tax" => [
          ["Tax / Capital Gains Tax", "CONTENT-ID-CAPITAL"],
          ["Tax / RTI (draft)", "CONTENT-ID-RTI"],
          ["Tax / VAT", "CONTENT-ID-VAT"],
        ] },
      Tagging::Linkables.new.mainstream_browse_pages,
    )
  end

  test "returns organisations" do
    assert_equal(
      [["Department for Education", "ebd15ade-73b2-4eaf-b1c3-43034a42eb37"], ["Student Loans Company", "9a9111aa-1db8-4025-8dd2-e08ec3175e72"]],
      Tagging::Linkables.new.organisations,
    )
  end
end
