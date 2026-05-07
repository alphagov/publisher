require "test_helper"

class EditionsHelperTest < ActionView::TestCase
  should "exclude the current edition format, not artefact kind, from conversion options" do
    artefact = stub(kind: "answer")
    edition = stub(format: "transaction", artefact: artefact)

    values = conversion_items(edition).map { |item| item[:value] }

    assert_includes values, "answer"
    assert_includes values, "completed_transaction"
    assert_not_includes values, "transaction"
  end
end
