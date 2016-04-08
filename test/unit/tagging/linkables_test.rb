require 'test_helper'

class LinkablesTest < ActiveSupport::TestCase
  test "returns sorted topics" do
    stub_linkables

    assert_equal({
      "Oil and Gas" => [
        ["Oil and Gas / Distillation (draft)", "CONTENT-ID-DISTILL"],
        ["Oil and Gas / Fields", "CONTENT-ID-FIELDS"],
        ["Oil and Gas / Wells", "CONTENT-ID-WELLS"]
      ]
    }, Tagging::Linkables.new.topics)
  end

  test "returns sorted browse pages" do
    stub_linkables

    assert_equal({
      "Tax" => [
        ["Tax / Capital Gains Tax", "CONTENT-ID-CAPITAL"],
        ["Tax / RTI (draft)", "CONTENT-ID-RTI"],
        ["Tax / VAT", "CONTENT-ID-VAT"]
      ]
    }, Tagging::Linkables.new.mainstream_browse_pages)
  end
end
