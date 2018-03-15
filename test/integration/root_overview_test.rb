require_relative '../integration_test_helper'

class RootOverviewTest < ActionDispatch::IntegrationTest
  setup do
    stub_holidays_used_by_fact_check
  end

  test "filtering by assigned user" do
    # This isn't right, really need a way to run actions when
    # logged in as particular users without having Signonotron running.
    #
    alice   = FactoryBot.create(:user, name: "Alice", uid: "alice")

    bob     = FactoryBot.create(:user, name: "Bob", uid: "bob")
    charlie = FactoryBot.create(:user, name: "Charlie", uid: "charlie")

    x = FactoryBot.create(:guide_edition, title: "XXX", slug: "xxx")
    y = FactoryBot.create(:guide_edition, title: "YYY", slug: "yyy")
    FactoryBot.create(:guide_edition, title: "ZZZ", slug: "zzz")

    bob.assign(x, alice)
    bob.assign(y, charlie)

    visit "/"

    filter_by_user("All")

    assert page.has_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by_user("Nobody")

    assert page.has_no_content?("XXX")
    assert page.has_no_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by_user("Charlie")

    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")

    visit "/"

    # Should remember last selection in session
    assert_equal charlie.uid, page.find_field("Assignee").value

    click_on "Drafts"
    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")
  end

  test "filtering by title content" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, title: "XXX")
    FactoryBot.create(:guide_edition, title: "YYY")

    visit "/"
    filter_by_user("All")

    filter_by_content("xXx")

    assert page.has_content?("XXX")
    assert page.has_no_content?("YYY")
  end

  test "filtering by title content should not lose the active section" do
    FactoryBot.create(:user)

    visit "/"
    click_on "Amends needed"

    filter_by_content("xXx")

    assert page.has_css?('h1', text: "Amends needed")
  end

  test "filtering by format" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, title: "Draft guide")
    FactoryBot.create(:transaction_edition, title: "Draft transaction")
    FactoryBot.create(:guide_edition, title: "Amends needed guide", state: 'amends_needed')
    FactoryBot.create(:transaction_edition, title: "Amends needed transaction", state: 'amends_needed')

    visit "/"

    filter_by_user("All")

    assert page.has_content?("Draft guide")
    assert page.has_content?("Draft transaction")

    filter_by_format("Guide")

    assert page.has_content?("Draft guide")
    assert page.has_no_content?("Draft transaction")

    click_on "Amends needed"

    assert page.has_no_content?("Draft guide")
    assert page.has_no_content?("Draft transaction")
    assert page.has_content?("Amends needed guide")
    assert page.has_no_content?("Amends needed transaction")
  end

  test "invalid sibling_in_progress should not break archived view" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, title: "XXX", state: 'archived', sibling_in_progress: 2)

    visit "/"
    filter_by_user("All")
    click_on "Archived"

    assert page.has_content?("XXX")
  end

  test "doesn't show disabled users in 'Assignee' select box" do
    disabled_user = FactoryBot.create(:disabled_user)

    visit "/"
    select_box = find_field('Assignee')
    refute page.has_xpath?(select_box.path + "/option[text() = '#{disabled_user.name}']")
  end

  test "Publications in review are ordered correctly" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, title: "XXX", slug: "xxx",
                       state: 'in_review', review_requested_at: 4.days.ago)
    FactoryBot.create(:guide_edition, title: "YYY", slug: "yyy",
                       state: 'in_review', review_requested_at: 2.days.ago)
    FactoryBot.create(:guide_edition, title: "ZZZ", slug: "zzz",
                       state: 'in_review', review_requested_at: 20.minutes.ago)

    visit "/"
    filter_by_user("All")
    click_on "In review"

    assert page.has_css?("#publication-list-container table tbody tr:first-child td:nth-child(5)", text: "4 days")
    assert page.has_css?("#publication-list-container table tbody tr:nth-child(2) td:nth-child(5)", text: "2 days")
    assert page.has_css?("#publication-list-container table tbody tr:nth-child(3) td:nth-child(5)", text: "20 minutes")

    click_on "Awaiting review"

    assert page.has_css?("#publication-list-container table tbody tr:first-child td:nth-child(5)", text: "20 minutes")
    assert page.has_css?("#publication-list-container table tbody tr:nth-child(2) td:nth-child(5)", text: "2 days")
    assert page.has_css?("#publication-list-container table tbody tr:nth-child(3) td:nth-child(5)", text: "4 days")
  end

  test "allows a user to claim 2i" do
    stub_linkables

    user = FactoryBot.create(:user)
    assignee = FactoryBot.create(:user)
    edition = FactoryBot.create(:guide_edition, title: "XXX", state: 'in_review',
                                 review_requested_at: Time.zone.now, assigned_to: assignee)

    visit "/"
    filter_by_user("All")

    click_on "In review"

    within("#publication-list-container tbody tr:first-child td:nth-child(6)") do
      find_button("Claim 2i").click
    end

    assert edition_url(edition), current_url
    assert page.has_content?("You are the reviewer of this guide.")
    assert page.has_select?("Reviewer", selected: user.name)
    assert page.has_select?("Assigned to", selected: assignee.name)
  end

  test "prevents claiming 2i when someone else has" do
    stub_linkables

    FactoryBot.create(:user)

    assignee = FactoryBot.create(:user)
    another_user = FactoryBot.create(:user, name: 'Another McPerson')
    edition = FactoryBot.create(:guide_edition, title: "XXX", state: 'in_review',
                                 review_requested_at: Time.zone.now, assigned_to: assignee)

    visit "/"
    filter_by_user("All")
    click_on "In review"

    edition.reviewer = another_user.name
    edition.save!

    within("#publication-list-container tbody tr:first-child td:nth-child(6)") do
      find_button("Claim 2i").click
    end

    assert edition_url(edition), current_url
    assert page.has_content?("Another McPerson has already claimed this 2i")
    assert page.has_select?("Reviewer", selected: another_user.name)
    assert page.has_select?("Assigned to", selected: assignee.name)

    select("", from: "Reviewer")
    click_on "Save"

    visit "/"
    filter_by_user("All")
    click_on "In review"

    within("#publication-list-container tbody tr:first-child td:nth-child(6)") do
      click_on "Claim 2i"
    end

    assert page.has_content?("You are the reviewer of this guide.")
  end

  test "prevents the assignee claiming 2i" do
    user = FactoryBot.create(:user)
    FactoryBot.create(
      :guide_edition,
      title: "XXX",
      state: 'in_review',
      review_requested_at: Time.zone.now,
      assigned_to: user
    )

    visit "/"
    filter_by_user("All")

    click_on "In review"

    assert page.has_css?("#publication-list-container tbody tr:first-child td:nth-child(6)", text: "")
  end

  test "filtering by published should show a table with an edition with a slug as a link" do
    FactoryBot.create(:user)
    FactoryBot.create(:guide_edition, state: "published", title: "Test", slug: "test-slug")

    visit "/"
    filter_by_user("All")

    click_on "Published"

    assert page.has_link?("/test-slug", href: "#{Plek.new.website_root}/test-slug")
  end
end
