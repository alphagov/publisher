require "test_helper"
# require "edition"
# require "parted"

class PartedTest < ActiveSupport::TestCase
  test "should merge part validation errors with parent document's errors" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(order: "1", title: "", slug: "overview")
    edition.parts.build(order: "2", title: "Prepare for your appointment", slug: "")
    edition.parts.build(order: "3", title: "Valid", slug: "valid")

    assert_not edition.valid?
    assert_equal("Enter a title for Part 1", edition.errors.to_hash[:"parts.title"][0])
    assert_equal(["Enter a slug for Part 2", "Slug can only consist of lower case characters, numbers and hyphens"], edition.errors.to_hash[:"parts.slug"])
    assert_equal 3, edition.errors.count
  end

  test "#whole_body returns ordered parts" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(order: "1", title: "Part 1", slug: "part_1")
    edition.parts.build(order: "3", title: "Part 3", slug: "part_3")
    edition.parts.build(order: "2", title: "Part 2", slug: "part_2")

    assert_equal("# Part 1\n\n\n\n# Part 2\n\n\n\n# Part 3\n\n", edition.whole_body)
  end
end
