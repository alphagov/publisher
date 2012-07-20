require 'test_helper'

class SearchableTest < ActiveSupport::TestCase

  def template_guide_edition
    edition = GuideEdition.create(:title => 'Guide', :slug => 'guide', :panopticon_id => 1)
    edition.start_work
    edition
  end

  def create_part(order, name, body = "this is the content body")
    Part.new(order: order,
             title: "Title of the #{name} part",
             body: body,
             slug: "title-of-#{name}-part")
  end

  test "should strip out govspeak when calling indexable_content_with_parts" do
    edition = template_guide_edition
    edition.parts << create_part(1, "first", "This is [link](http://example.net/) text.")
    edition.parts << create_part(2, "second", "This is some **version** text.")

    edition.state = "published"
    edition.safely.save!

    assert_equal "Title of the first part This is link text. Title of the second part This is some version text.", edition.indexable_content_with_parts
  end

  test "should strip out govspeak when asking for indexable content" do
    edition = template_guide_edition
    edition.parts << create_part(1, "first", "This is [link](http://example.net/) text.")
    edition.parts << create_part(2, "second", "This is some **version** text.")

    edition.state = "published"
    edition.safely.save!

    assert_equal "Title of the first part This is link text. Title of the second part This is some version text.", edition.indexable_content
  end
end
