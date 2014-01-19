require 'test_helper'

class PathsHelperTest < ActionView::TestCase
  test "it raises an exception when generating a front end path with a blank slug" do
    guide = GuideEdition.new
    assert_raises RuntimeError do
      publication_front_end_path(guide)
    end
  end
end
