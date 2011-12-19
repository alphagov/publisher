require 'test_helper'

class Admin::GuidesHelperTest < ActionView::TestCase
  include Admin::GuidesHelper

  test "it raises an exception when generating a front end path with a blank slug" do
    guide = Guide.new
    assert_raises do
      publication_front_end_path(guide)
    end
  end
end
