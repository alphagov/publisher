require "test_helper"

class LinkablesTest < ActiveSupport::TestCase
  setup do
    stub_linkables
  end

  test "returns sorted browse pages" do
    assert_equal(
      {
        "Tax" => [
          ["Tax / Capital Gains Tax", "CONTENT-ID-CAPITAL"],
          ["Tax / RTI (draft)", "CONTENT-ID-RTI"],
          ["Tax / VAT", "CONTENT-ID-VAT"],
        ],
      },
      Tagging::Linkables.new.mainstream_browse_pages,
    )
  end

  test "returns organisations" do
    assert_equal(
      [["Student Loans Company", "9a9111aa-1db8-4025-8dd2-e08ec3175e72"]],
      Tagging::Linkables.new.organisations,
    )
  end
end
