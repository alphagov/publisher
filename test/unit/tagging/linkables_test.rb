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
      [["Department for Education", "ebd15ade-73b2-4eaf-b1c3-43034a42eb37"],
       ["Student Loans Company", "9a9111aa-1db8-4025-8dd2-e08ec3175e72"],
       ["Test Org 3 No Acronym", "87fb8d96-cd9f-4de2-839c-e7ae0381856a"],
       ["Test Org 4 No Acronym in Draft (draft)", "72a7eb6c-93bf-4c33-813e-3c89d22e80bb"],
       ["Test Org 5 Acronym in Draft (draft)", "432906aa-751e-4618-b938-d8321a155527"]],
      Tagging::Linkables.new.organisations,
    )
  end
end
