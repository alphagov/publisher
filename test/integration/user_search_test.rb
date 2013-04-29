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

  test "selecting another user" do
    guides = FactoryGirl.build_list(:guide_edition, 2)
    other_user = FactoryGirl.create(:user, name: "Bob", uid: "bob")

    # Assigning manually so it doesn't show up in Alice's list too
    guides[0].assigned_to_id = other_user.id
    guides[0].save!

    visit "/admin/user_search"
    within :css, "form.user-filter-form" do
      select other_user.name, from: "Filter by user"
      click_button "Filter"
    end

    assert page.has_content?("Search by user")

    assert page.has_content?(guides[0].title)
    refute page.has_content?(guides[1].title)
  end

end
