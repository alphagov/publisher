require "test_helper"

class PartTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:title).with_message(/Enter a title/)
    should validate_presence_of(:slug).with_message(/Enter a slug/)

    should validate_exclusion_of(:slug).in_array(%w[video]).with_message(/Slug can not be 'video'/)
    should allow_value("valid-slug-123").for(:slug)
    should_not allow_value("Invalid **").for(:slug).with_message(/Slug can only consist of lower case characters/)

    context "when the part is persisted" do
      setup do
        @edition = create(:guide_edition_with_two_parts)
        @part = @edition.parts.second
      end

      should "include the chapter number in the title error message" do
        @part.title = nil
        @part.valid?
        assert_includes @part.errors[:title], "Enter a title for Chapter 2"
      end

      should "include the chapter number in the slug presence error message" do
        @part.slug = nil
        @part.valid?
        assert_includes @part.errors[:slug], "Enter a slug for Chapter 2"
      end

      should "include the chapter number in the slug format error message" do
        @part.slug = "***"
        @part.valid?
        assert_includes @part.errors[:slug], "Slug for Chapter 2 can only consist of lower case characters, numbers and hyphens"
      end

      should "include the chapter number in the slug 'video' error message" do
        @part.slug = "video"
        @part.valid?
        assert_includes @part.errors[:slug], "Slug for Chapter 2 can not be 'video'"
      end
    end
  end
end
