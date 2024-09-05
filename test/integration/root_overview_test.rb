# frozen_string_literal: true

require_relative "../integration_test_helper"

class RootOverviewTest < IntegrationTest
  setup do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, true)
  end

  should "be able to view different pages of results" do
    alice = FactoryBot.create(:user, :govuk_editor, name: "Alice", uid: "alice")
    FactoryBot.create(:guide_edition, title: "Guides and Gals", assigned_to: alice)
    FactoryBot.create_list(:guide_edition, FilteredEditionsPresenter::ITEMS_PER_PAGE, assigned_to: alice)

    visit "/"
    assert_content("21 document(s)")
    assert_no_content("Guides and Gals")

    click_on "Next"
    assert_content("21 document(s)")
    assert_content("Guides and Gals")

    click_on "Prev"
    assert_content("21 document(s)")
    assert_no_content("Guides and Gals")
  end

  should "filter by assigned user" do
    alice = FactoryBot.create(:user, :govuk_editor, name: "Alice", uid: "alice")
    bob     = FactoryBot.create(:user, :govuk_editor, name: "Bob", uid: "bob")
    charlie = FactoryBot.create(:user, :govuk_editor, name: "Charlie", uid: "charlie")

    guide_edition_x = FactoryBot.create(:guide_edition, title: "XXX", slug: "xxx")
    guide_edition_y = FactoryBot.create(:guide_edition, title: "YYY", slug: "yyy")
    FactoryBot.create(:guide_edition, title: "ZZZ", slug: "zzz")

    bob.assign(guide_edition_x, alice)
    bob.assign(guide_edition_y, charlie)

    visit "/"

    filter_by_user("All")

    assert page.has_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by_user("Charlie")

    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")
  end

  should "filter by title content" do
    FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(:guide_edition, title: "XXX")
    FactoryBot.create(:guide_edition, title: "YYY")

    visit "/"
    filter_by_user("All")

    filter_by_content("xXx")

    assert page.has_content?("XXX")
    assert page.has_no_content?("YYY")
  end

  should "not lose the active section when filtering by title content" do
    FactoryBot.create(:user, :govuk_editor)

    visit "/"
    filter_by_status("Amends needed")
    filter_by_content("xXx")

    assert page.has_css?(".publications-filter input[value='amends_needed'][checked]")
  end

  should "filter by content type" do
    FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(:guide_edition, title: "Draft guide")
    FactoryBot.create(:transaction_edition, title: "Draft transaction")
    FactoryBot.create(:guide_edition, title: "Amends needed guide", state: "amends_needed")
    FactoryBot.create(:transaction_edition, title: "Amends needed transaction", state: "amends_needed")

    visit "/"

    filter_by_user("All")

    assert page.has_content?("Draft guide")
    assert page.has_content?("Draft transaction")

    filter_by_content_type("Guide")

    assert page.has_content?("Draft guide")
    assert page.has_no_content?("Draft transaction")

    filter_by_status("Amends needed")

    assert page.has_no_content?("Draft guide")
    assert page.has_no_content?("Draft transaction")
    assert page.has_content?("Amends needed guide")
    assert page.has_no_content?("Amends needed transaction")
  end

  should "not break archived view when invalid sibling_in_progress" do
    FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(:guide_edition, title: "XXX", state: "archived", sibling_in_progress: 2)

    visit "/"
    filter_by_user("All")
    filter_by_status("Archived")

    assert page.has_content?("XXX")
  end

  should "not show disabled users in 'Assignee' select box" do
    disabled_user = FactoryBot.create(:disabled_user)

    visit "/"
    select_box = find_field("Assigned to")
    assert page.has_no_xpath?(select_box.path + "/option[text() = '#{disabled_user.name}']")
  end

  should "display publications in review correctly ordered" do
    FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(
      :guide_edition,
      title: "XXX",
      slug: "xxx",
      state: "in_review",
      review_requested_at: 4.days.ago,
    )
    FactoryBot.create(
      :guide_edition,
      title: "YYY",
      slug: "yyy",
      state: "in_review",
      review_requested_at: 2.days.ago,
    )
    FactoryBot.create(
      :guide_edition,
      title: "ZZZ",
      slug: "zzz",
      state: "in_review",
      review_requested_at: 20.minutes.ago,
    )

    visit "/"
    filter_by_user("All")
    filter_by_status("In review")

    find(".publications-table tr:nth-child(1) details").click
    assert page.has_css?(".publications-table tr:nth-child(1) details .govuk-summary-list__row:nth-child(3) .govuk-summary-list__value", text: "20 minutes")

    find(".publications-table tr:nth-child(2) details").click
    assert page.has_css?(".publications-table tr:nth-child(2) details .govuk-summary-list__row:nth-child(3) .govuk-summary-list__value", text: "2 days")

    find(".publications-table tr:nth-child(3) details").click
    assert page.has_css?(".publications-table tr:nth-child(3) details .govuk-summary-list__row:nth-child(3) .govuk-summary-list__value", text: "4 days")
  end

  should "allow a user to claim 2i" do
    stub_linkables
    stub_holidays_used_by_fact_check

    user = FactoryBot.create(:user, :govuk_editor)
    assignee = FactoryBot.create(:user, :govuk_editor)
    edition = FactoryBot.create(
      :guide_edition,
      title: "XXX",
      state: "in_review",
      review_requested_at: Time.zone.now,
      assigned_to: assignee,
    )

    visit "/"
    filter_by_user("All")
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    within(".publications-table tr:first-child details .govuk-summary-list__row:nth-child(4) .govuk-summary-list__value") do
      find_button("Claim 2i").click
    end

    assert edition_url(edition), current_url
    assert page.has_content?("You are the reviewer of this guide.")
    assert page.has_select?("Reviewer", selected: user.name)
    assert page.has_select?("Assigned to", selected: assignee.name)
  end

  should "prevent the current user from claiming 2i when the publication is already claimed and allow the user to claim 2i when the publication is not claimed for 2i" do
    stub_linkables
    stub_holidays_used_by_fact_check

    FactoryBot.create(:user, :govuk_editor)

    assignee = FactoryBot.create(:user, :govuk_editor)
    another_user = FactoryBot.create(:user, :govuk_editor, name: "Another McPerson")
    edition = FactoryBot.create(
      :guide_edition,
      title: "XXX",
      state: "in_review",
      review_requested_at: Time.zone.now,
      assigned_to: assignee,
    )

    visit "/"
    filter_by_user("All")
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    edition.reviewer = another_user.name
    edition.save!

    within(".publications-table tr:first-child details .govuk-summary-list__row:nth-child(4) .govuk-summary-list__value") do
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
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    within(".publications-table tr:first-child details .govuk-summary-list__row:nth-child(4) .govuk-summary-list__value") do
      find_button("Claim 2i").click
    end

    assert page.has_content?("You are the reviewer of this guide.")
  end

  should "prevent the assignee claiming 2i" do
    user = FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(
      :guide_edition,
      title: "XXX",
      state: "in_review",
      review_requested_at: Time.zone.now,
      assigned_to: user,
    )

    visit "/"
    filter_by_user("All")
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    assert page.has_no_button?("Claim 2i")
  end

  should "allow Welsh editors to see claim 2i button in Welsh editions" do
    stub_linkables
    stub_holidays_used_by_fact_check

    FactoryBot.create(:guide_edition, :in_review, :welsh)
    welsh_editor = FactoryBot.create(:user, :welsh_editor)

    login_as(welsh_editor)
    visit "/"
    filter_by_user("All")
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    assert page.has_button?("Claim 2i")
  end

  should "not allow Welsh editors to see claim 2i button in non-Welsh editions" do
    stub_linkables
    stub_holidays_used_by_fact_check

    FactoryBot.create(:guide_edition, :in_review, panopticon_id: FactoryBot.create(:artefact).id)
    welsh_editor = FactoryBot.create(:user, :welsh_editor)

    login_as(welsh_editor)
    visit "/"
    filter_by_user("All")
    filter_by_status("In review")
    find(".publications-table tr:first-child details").click

    assert_not page.has_button?("Claim 2i")
  end

  should "not render popular links edition" do
    FactoryBot.create(:user, :govuk_editor)
    FactoryBot.create(:guide_edition, title: "Draft guide")
    FactoryBot.create(:transaction_edition, title: "Draft transaction")
    FactoryBot.create(:popular_links, title: "Popular links edition")

    visit "/"

    filter_by_user("All")

    assert page.has_content?("Draft guide")
    assert page.has_content?("Draft transaction")
    assert page.has_content?("Draft guide")
    assert page.has_no_content?("Popular links edition")
  end
end
