require 'test_helper'

class Admin::BaseHelperTest < ActionView::TestCase
  test "should strip govspeak and markdown when using indexable_content_with_parts" do
    edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, state: "published")
    assert_equal "Some Part Title! This is some version text. Another Part Title This is link text.", edition.indexable_content_with_parts
  end

  test "should provide same text back" do
    assert_equal "some dummy text", govspeak_to_text("some dummy text")
  end

  test "should remove markdown from provided string" do
    assert_equal "some dummy text", govspeak_to_text("some *dummy* text")
    assert_equal "some dummy text", govspeak_to_text("some **dummy** text")
    assert_equal "some dummy text", govspeak_to_text("some\n\n* dummy\ntext")
    assert_equal "some dummy text", govspeak_to_text("some\n\n1. dummy\ntext")
  end

  test "should remove govspeak from provided string" do
    assert_equal "This is a warning callout", govspeak_to_text("%This is a warning callout%")
    assert_equal "Example : Open the pod bay doors", govspeak_to_text("$E\n**Example**: Open the pod bay doors\n$E")
    assert_equal "This is a very important message or warning", govspeak_to_text("@This is a very important message or warning@")
    assert_equal "The VAT rate is 20%", govspeak_to_text("{::highlight-answer}\nThe VAT rate is *20%*\n{:/highlight-answer}")
  end
end
