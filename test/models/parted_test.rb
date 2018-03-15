require "test_helper"
# require "edition"
# require "parted"

class PartedTest < ActiveSupport::TestCase
  test "should merge part validation errors with parent document's errors" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(_id: '54c10d4d759b743528000010', order: '1', title: "", slug: "overview")
    edition.parts.build(_id: '54c10d4d759b743528000011', order: '2', title: "Prepare for your appointment", slug: "")
    edition.parts.build(_id: '54c10d4d759b743528000012', order: '3', title: "Valid", slug: "valid")

    refute edition.valid?

    assert_equal({ title: ["can't be blank"] }, edition.errors[:parts][0]['54c10d4d759b743528000010:1'])
    assert_equal({ slug: ["can't be blank", "is invalid"] }, edition.errors[:parts][0]['54c10d4d759b743528000011:2'])
    assert_equal 2, edition.errors[:parts][0].length
  end

  test "#whole_body returns ordered parts" do
    edition = FactoryBot.create(:guide_edition)
    edition.parts.build(_id: '54c10d4d759b743528000010', order: '1', title: "Part 1", slug: "part_1")
    edition.parts.build(_id: '54c10d4d759b743528000011', order: '3', title: "Part 3", slug: "part_3")
    edition.parts.build(_id: '54c10d4d759b743528000012', order: '2', title: "Part 2", slug: "part_2")
    assert_equal("# Part 1\n\n\n\n# Part 2\n\n\n\n# Part 3\n\n", edition.whole_body)
  end
end
