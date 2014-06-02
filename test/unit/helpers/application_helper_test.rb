require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "that current environment name is development" do
    assert_equal environment_name, "development"
  end
end
