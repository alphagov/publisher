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

    visit "/user_search"

    assert page.has_content? @guide.title
  end

  test "excluding archived editions" do
    @guide = FactoryGirl.create(:guide_edition, state: 'archived')
    @user.record_note @guide, "I like this guide"

    visit "/user_search"

    refute page.has_content? @guide.title
  end

  test "filtering by keyword" do
    guide = FactoryGirl.create(
      :guide_edition, title: "Vehicle insurance")
    @user.record_note guide, "I like this guide"
    another_guide = FactoryGirl.create(
      :guide_edition, title: "Growing your business")
    @user.record_note another_guide, "I like this guide"

    visit "/user_search"
    within :css, "form.user-filter-form" do
      fill_in :string_filter, with: "insurance"
      click_button "Filter publications"
    end
    assert page.has_content?("Vehicle insurance")
    refute page.has_content?("Growing your business")
  end

  test "excluding archived editions from keyword filtered results" do
    guide = FactoryGirl.create(
      :guide_edition, title: "Vehicle insurance", state: "archived")
    @user.record_note guide, "I like this guide"
    visit "/user_search"
    within :css, "form.user-filter-form" do
      fill_in :string_filter, with: "insurance"
      click_button "Filter publications"
    end
    refute page.has_content?("Vehicle insurance")
  end

  test "selecting another user" do
    guides = FactoryGirl.build_list(:guide_edition, 2)
    other_user = FactoryGirl.create(:user, name: "Bob", uid: "bob")

    # Assigning manually so it doesn't show up in Alice's list too
    guides[0].assigned_to_id = other_user.id
    guides[0].save!

    visit "/user_search"
    within :css, "form.user-filter-form" do
      select other_user.name, from: "Filter by user"
      click_button "Filter publications"
    end

    assert page.has_content?("Search by user")

    assert page.has_content?(guides[0].title)
    refute page.has_content?(guides[1].title)
  end

  test "doesn't show disabled users in 'Filter by user' select box" do
    disabled_user = FactoryGirl.create(:disabled_user)

    visit "/user_search"

    select_box = find_field('Filter by user')
    refute page.has_xpath?(select_box.path + "/option[text() = '#{disabled_user.name}']")
  end
end
