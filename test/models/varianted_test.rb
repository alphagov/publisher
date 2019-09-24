require "test_helper"
# require "edition"
# require "varianted"

class VariantedTest < ActiveSupport::TestCase
  test "should merge variant validation errors with parent document's errors" do
    edition = FactoryBot.create(:transaction_edition)
    edition.variants.build(_id: "54c10d4d759b743528000010", order: "1", title: "", slug: "overview")
    edition.variants.build(_id: "54c10d4d759b743528000011", order: "2", title: "Prepare for your appointment", slug: "")
    edition.variants.build(_id: "54c10d4d759b743528000012", order: "3", title: "Valid", slug: "valid")

    refute edition.valid?

    assert_equal({ title: ["can't be blank"] }, edition.errors[:variants][0]["54c10d4d759b743528000010:1"])
    assert_equal({ slug: ["can't be blank", "is invalid"] }, edition.errors[:variants][0]["54c10d4d759b743528000011:2"])
    assert_equal 2, edition.errors[:variants][0].length
  end
end
