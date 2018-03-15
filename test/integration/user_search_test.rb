require_relative '../integration_test_helper'

class UserSearchTest < ActionDispatch::IntegrationTest
  setup do
    alice = FactoryBot.create(:user, name: "Alice", uid: "alice")
    GDS::SSO.test_user = alice
    @user = alice
  end

  test "filtering by assigned user" do
    @guide = FactoryBot.create(:guide_edition)
    @user.record_note @guide, "I like this guide"

    visit "/user_search"

    assert page.has_content? @guide.title
  end

  test "excluding archived editions" do
    @guide = FactoryBot.create(:guide_edition, state: 'archived')
    @user.record_note @guide, "I like this guide"

    visit "/user_search"

    refute page.has_content? @guide.title
  end

  test "filtering by format" do
    guide = FactoryBot.create(
      :guide_edition, title: "Vehicle insurance")
    @user.record_note guide, "I like this guide"
    another_guide = FactoryBot.create(
      :guide_edition, title: "Growing your business")
    @user.record_note another_guide, "I like this guide"
    answer = FactoryBot.create(
      :answer_edition, title: "Vehicle answer")
    @user.record_note answer, "I like this answer"

    visit "/user_search"

    filter_by_format("Guide")

    assert page.has_content?("Vehicle insurance")
    assert page.has_content?("Growing your business")
    refute page.has_content?("Vehicle answer")

    filter_by_content("Vehicle")

    assert page.has_content?("Vehicle insurance")
    refute page.has_content?("Growing your business")
    refute page.has_content?("Vehicle answer")

    filter_by_format("Answer")

    refute page.has_content?("Vehicle insurance")
    refute page.has_content?("Growing your business")
    assert page.has_content?("Vehicle answer")
  end

  test "filtering by keyword" do
    guide = FactoryBot.create(
      :guide_edition, title: "Vehicle insurance")
    @user.record_note guide, "I like this guide"
    another_guide = FactoryBot.create(
      :guide_edition, title: "Growing your business")
    @user.record_note another_guide, "I like this guide"

    visit "/user_search"

    filter_by_content "insurance"

    assert page.has_content?("Vehicle insurance")
    refute page.has_content?("Growing your business")
  end


  test "excluding archived editions from keyword filtered results" do
    guide = FactoryBot.create(
      :guide_edition, title: "Vehicle insurance", state: "archived")
    @user.record_note guide, "I like this guide"
    visit "/user_search"

    filter_by_content "insurance"

    refute page.has_content?("Vehicle insurance")
  end

  test "selecting another user" do
    guides = FactoryBot.build_list(:guide_edition, 2)
    other_user = FactoryBot.create(:user, name: "Bob", uid: "bob")

    # Assigning manually so it doesn't show up in Alice's list too
    guides[0].assigned_to_id = other_user.id
    guides[0].save!

    visit "/user_search"

    filter_by_user other_user.name, from: "User"

    assert page.has_content?("Search by user")

    assert page.has_content?(guides[0].title)
    refute page.has_content?(guides[1].title)
  end

  test "doesn't show disabled users in 'Filter by user' select box" do
    disabled_user = FactoryBot.create(:disabled_user)

    visit "/user_search"

    select_box = find_field('User')
    refute page.has_xpath?(select_box.path + "/option[text() = '#{disabled_user.name}']")
  end
end
