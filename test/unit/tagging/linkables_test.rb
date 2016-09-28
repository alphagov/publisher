require 'test_helper'

class LinkablesTest < ActiveSupport::TestCase
  setup do
    stub_linkables
  end

  test "returns sorted topics" do
    assert_equal({
      "Oil and Gas" => [
        ["Oil and Gas / Distillation (draft)", "CONTENT-ID-DISTILL"],
        ["Oil and Gas / Fields", "CONTENT-ID-FIELDS"],
        ["Oil and Gas / Wells", "CONTENT-ID-WELLS"]
      ]
    }, Tagging::Linkables.new.topics)
  end

  test "returns sorted browse pages" do
    assert_equal({
      "Tax" => [
        ["Tax / Capital Gains Tax", "CONTENT-ID-CAPITAL"],
        ["Tax / RTI (draft)", "CONTENT-ID-RTI"],
        ["Tax / VAT", "CONTENT-ID-VAT"]
      ]
    }, Tagging::Linkables.new.mainstream_browse_pages)
  end

  test "returns organisations" do
    assert_equal(
      [["Student Loans Company", "9a9111aa-1db8-4025-8dd2-e08ec3175e72"]],
      Tagging::Linkables.new.organisations
    )
  end
end
