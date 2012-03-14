require 'test_helper'

class SearchableTest < ActiveSupport::TestCase

  def template_guide_edition
    edition = GuideEdition.create(:name => 'Guide', :slug => 'guide', :panopticon_id => 1, :title => 'Guide')
    edition.start_work
    edition
  end

  test "section name is normalized" do
    edition = template_guide_edition
    edition.section = "Cats and Dogs"
    assert_equal "cats-and-dogs", edition.search_index['section']
  end

  test "subsection field of search_index is populated by splitting section on colon" do
    edition = template_guide_edition
    edition.section = "Crime and Justice:Prison"
    assert_equal 'crime-and-justice', edition.search_index['section']
    assert_equal 'prison', edition.search_index['subsection']
  end

end
