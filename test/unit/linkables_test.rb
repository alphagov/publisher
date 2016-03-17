require 'test_helper'

class LinkablesTest < ActiveSupport::TestCase
  test "returns sorted topics" do
    stub_linkables

    assert_equal({
      "Oil and Gas" => [
        ["Oil and Gas / Distillation (draft)", "oil-and-gas/distillation"],
        ["Oil and Gas / Fields", "oil-and-gas/fields"],
        ["Oil and Gas / Wells", "oil-and-gas/wells"]
      ]
    }, Linkables.topics)
  end

  test "returns sorted browse pages" do
    stub_linkables

    assert_equal({
      "Tax" => [
        ["Tax / Capital Gains Tax", "tax/capital-gains"],
        ["Tax / RTI (draft)", "tax/rti"],
        ["Tax / VAT", "tax/vat"]
      ]
    }, Linkables.mainstream_browse_pages)
  end
end
