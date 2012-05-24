require_relative '../integration_test_helper'

class UserSearchTest < ActionDispatch::IntegrationTest

  def setup
    alice = FactoryGirl.create(:user, name: "Alice", uid: "alice")
    GDS::SSO.test_user = alice
    @user = alice
  end

  def teardown
    GDS::SSO.test_user = nil
  end

  test "filtering by assigned user" do
    @guide = FactoryGirl.create(:guide_edition)
    @user.record_note @guide, "I like this guide"

    visit "/admin/user_search"

    assert page.has_content? @guide.title
  end
end
