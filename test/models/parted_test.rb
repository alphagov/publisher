require "test_helper"

class PartedTest < ActiveSupport::TestCase
  test "should merge part validation errors with parent document's errors" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(id: "101", order: "1", title: "", slug: "overview")
    edition.parts.build(id: "102", order: "2", title: "Prepare for your appointment", slug: "")
    edition.parts.build(id: "103", order: "3", title: "Valid", slug: "valid")
    assert_not edition.valid?

    assert_equal({ title: ["Enter a title for Chapter 1"] }, edition.editionable.errors[:parts][0]["101:1"])
    assert_equal 2, edition.editionable.errors[:parts][0].length
  end

  test "#whole_body returns ordered parts" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(order: "1", title: "Part 1", slug: "part-1")
    edition.parts.build(order: "3", title: "Part 3", slug: "part-3")
    edition.parts.build(order: "2", title: "Part 2", slug: "part-2")
    edition.save!

    assert_equal("# Part 1\n\n\n\n# Part 2\n\n\n\n# Part 3\n\n", edition.editionable.whole_body)
  end
end
