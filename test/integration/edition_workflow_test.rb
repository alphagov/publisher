require 'integration_test_helper'
require 'gds_api/test_helpers/calendars'

class EditionWorkflowTest < JavascriptIntegrationTest
  include GdsApi::TestHelpers::Calendars
  attr_reader :alice, :bob, :guide

  setup do
    stub_linkables
    stub_holidays_used_by_fact_check

    @alice = FactoryBot.create(:user, name: "Alice")
    @bob = FactoryBot.create(:user, name: "Bob")

    @guide = FactoryBot.create(:guide_edition)
    login_as "Alice"
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "should show and update a guide's assigned person" do
    assert_nil guide.assigned_to

    visit_edition guide
    select "Bob", from: "Assigned to"
    save_edition_and_assert_success
    guide.reload

    assert_equal guide.assigned_to, bob
  end

  test "doesn't show disabled users in 'Assigned to' select box" do
    disabled_user = FactoryBot.create(:disabled_user)

    visit_edition guide

    assert page.has_no_xpath?("//select[@id='edition_assigned_to_id']/option[text() = '#{disabled_user.name}']")
  end

  test "the customised message for fact-check is pre-loaded with a 5 working days deadline message" do
    today = Date.parse('2017-04-28')
    calendars_has_a_bank_holiday_on(Date.parse('2017-05-01'), in_division: 'england-and-wales')

    Timecop.freeze(today) do
      guide.update_attribute(:state, 'ready')
      visit_edition guide

      click_link('Fact check')

      within "#send_fact_check_form" do
        customised_message = page.find_field('Customised message')
        assert customised_message
        assert customised_message.value.include? 'Deadline: 8 May 2017 (5 working days from today - 28 April 2017)'
      end
    end
  end

  test "can send guide to fact-check when in ready state" do
    guide.update_attribute(:state, 'ready')
    visit_edition guide

    click_link('Fact check')

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user@example.com"
      click_on "Send"
    end

    assert page.has_css?('.label', text: 'Fact check')

    click_on "History and notes"
    assert page.has_content? 'Send fact check by Alice'
    assert page.has_content? 'Request sent to user@example.com'

    guide.reload
    assert guide.fact_check?

    fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? 'user@example.com' }.last
    assert fact_check_email
    assert_equal "‘[#{guide.title}]’ GOV.UK preview of new edition", fact_check_email.subject
    assert_equal "Blah", fact_check_email.body.to_s
  end

  test "can send guide to several fact-check recipients with comma separated emails" do
    guide.update_attribute(:state, 'ready')
    visit_edition guide

    click_link('Fact check')

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1@example.com, user2@example.com"
      click_on "Send"
    end

    assert page.has_css?('.label', text: 'Fact check')
    guide.reload
    assert guide.fact_check?

    fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? 'user1@example.com' }.last
    assert fact_check_email
    assert_includes fact_check_email.to, 'user2@example.com'
    assert_equal "‘[#{guide.title}]’ GOV.UK preview of new edition", fact_check_email.subject
    assert_equal "Blah", fact_check_email.body.to_s
  end

  test "the fact-check form validates emails and won't send if they are mangled" do
    guide.update_attribute(:state, 'ready')
    visit_edition guide

    click_link('Fact check')

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1"
      click_on "Send"
    end

    assert page.has_content? 'The email addresses you entered appear to be invalid.'
    guide.reload
    assert_not guide.fact_check?

    click_link('Fact check')

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1@example.com user2@example.com"
      click_on "Send"
    end

    assert page.has_content? 'The email addresses you entered appear to be invalid.'
    guide.reload
    assert_not guide.fact_check?

    click_link('Fact check')

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1, user2@example.com"
      click_on "Send"
    end

    assert page.has_content? 'The email addresses you entered appear to be invalid.'
    guide.reload
    assert_not guide.fact_check?
  end

  test "a guide in the ready state can be requested to make more amendments" do
    guide.update_attribute(:state, 'ready')

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "a guide in the fact-check state can be requested to make more amendments" do
    guide.update_attribute(:state, 'fact_check')

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "a guide in the fact-check state can resend the email" do
    guide.update_attribute(:state, 'ready')
    visit_edition guide

    click_link('Fact check')

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah blah fact check message"
      fill_in "Email address", with: "user-to-ask-for-fact-check@example.com"
      click_on "Send"
    end

    ActionMailer::Base.deliveries.clear

    visit_edition guide
    send_for_generic_action guide, "Resend fact check email" do
      assert page.has_content? 'Blah blah fact check message'
      assert page.has_content? 'user-to-ask-for-fact-check@example.com'
      click_on 'Resend'
    end

    visit_edition guide
    click_on "History and notes"
    assert page.has_content? 'Resend fact check by Alice'

    resent_fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? 'user-to-ask-for-fact-check@example.com' }.last
    assert resent_fact_check_email
    assert_equal "‘[#{guide.title}]’ GOV.UK preview of new edition", resent_fact_check_email.subject
    assert_equal "Blah blah fact check message", resent_fact_check_email.body.to_s
  end

  test "can flag guide for review" do
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
    filter_for_all_users
    view_filtered_list "In review"

    assert page.has_content? guide.title
  end

  test "cannot review own guide" do
    guide.assigned_to = alice

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"

    assert page.has_selector?(".alert-info")
    assert has_no_link? "OK for publication"
  end

  test "cannot be the guide reviewer and assignee" do
    guide.assigned_to = bob
    guide.update_attribute(:state, 'in_review')

    visit_edition guide
    select("Bob", from: "Reviewer")
    save_edition_and_assert_error

    assert page.has_css?(".form-group.has-error li", text: "can't be the assignee")
  end

  test "can deselect the guide reviewer" do
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"

    select("", from: "Reviewer")
    save_edition_and_assert_success
  end

  test "can unassign the guide" do
    guide.assigned_to = bob

    visit_edition guide
    select "", from: "Assigned to"
    save_edition_and_assert_success
    guide.reload

    assert_nil guide.assignee
    assert page.has_select?("Assigned to", selected: "")
  end

  test "can become the guide reviewer" do
    guide.assigned_to = bob

    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"

    visit_edition guide

    select("Alice", from: "Reviewer")
    save_edition_and_assert_success
  end

  test "can review another's guide" do
    guide.update_attribute(:state, 'in_review')
    guide.assigned_to = bob

    visit_edition guide
    assert page.has_selector?(".alert-info")
    assert has_link? "Needs more work"
    assert has_link? "OK for publication"
  end

  test "review failed" do
    guide.update_attribute(:state, 'in_review')
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "review passed" do
    guide.update_attribute(:state, 'in_review')

    visit_edition guide
    send_action guide, "OK for publication", "OK for publication", "Yup, looks good"
    filter_for_all_users
    view_filtered_list "Ready"
    assert page.has_content? guide.title
  end

  test "can skip fact-check" do
    guide.update_attribute(:state, 'fact_check')

    visit_edition guide

    click_on "Admin"
    click_on "Skip fact check"

    # This information is not quite correct but it is the current behaviour.
    # Adding this test as an aid to future improvements
    assert page.has_content? "Fact check was skipped for this edition."
    filter_for_all_users
    view_filtered_list "Ready"
    assert page.has_content? guide.title

    visit_edition guide
    assert page.has_content? "Request this edition to be amended further."
    assert page.has_content? "Needs more work"
  end

  test "can progress from fact-check" do
    guide.update_attribute(:state, 'fact_check_received')

    visit_edition guide
    send_action guide, "Minor or no changes required", "Approve fact check", "Hurrah!"
    filter_for_all_users
    view_filtered_list "Ready"

    assert page.has_content? guide.title
  end

  test "can go back to fact-check from fact-check received" do
    guide.update_attribute(:state, 'fact_check_received')

    visit_edition guide
    send_for_fact_check guide
    visit_edition guide

    assert page.has_css?('.label', text: 'Fact check')
  end

  test "can create a new edition from the listings screens" do
    guide.update_attribute(:state, 'published')

    visit '/'
    filter_for_all_users
    view_filtered_list "Published"
    click_on "Create new edition"

    assert page.has_content? "New edition created"
  end

  test "can preview a draft article on draft-origin" do
    guide.update_attribute(:state, 'draft')

    visit_edition guide
    assert page.has_text?('Preview')
  end

  test "can view a published article on the live site" do
    guide.update_attribute(:state, 'published')

    visit_edition guide
    assert page.has_text?('View this on the GOV.UK website')
  end

  test "cannot create a new edition for a retired format" do
    FactoryBot.create(:video_edition, state: 'archived')

    visit '/'
    select "Video", from: "Format"
    filter_for_all_users
    view_filtered_list "Archived"

    assert page.has_no_content? "Create new edition"
  end

  test "cannot preview an archived article" do
    guide.update_attribute(:state, 'archived')

    visit_edition guide
    assert page.has_css?('#edit div div.navbar.navbar-inverse.navbar-fixed-bottom.text-center div div div a:nth-child(2)', text: 'Preview')
  end

  test "should link to a newer sibling" do
    artefact = FactoryBot.create(:artefact)
    old_edition = FactoryBot.create(
      :guide_edition,
      panopticon_id: artefact.id,
      state: "published",
      version_number: 1
    )
    new_edition = FactoryBot.create(
      :guide_edition,
      panopticon_id: artefact.id,
      state: "draft",
      version_number: 2
    )
    visit_edition old_edition
    assert page.has_link?(
      "Edit existing newer edition",
      href: edition_path(new_edition)
    ), "Page should have edit link"
  end

  test "should show an alert if another person has created a newer edition" do
    guide.update_attribute(:state, 'published')

    filter_for_all_users
    view_filtered_list "Published"

    # Simulate that someone has clicked on 'Create new edition'
    # while current user has been viewing the list of published editions
    new_edition = guide.build_clone(GuideEdition)
    new_edition.save

    # Current user now decides to click the button
    click_on "Create new edition"

    assert page.has_content?("Another person has created a newer edition")
    assert page.has_css?('.label', text: 'Published')
  end

  test "should display a retired message if a format has been retired" do
    artefact = FactoryBot.create(:artefact)
    edition = FactoryBot.create(
      :video_edition,
      panopticon_id: artefact.id,
      state: "archived",
      version_number: 1
    )
    artefact.update_attribute(:state, "archived")

    visit '/'
    select "Video (Retired)", from: "Format"

    visit_edition edition
    assert page.has_content?("This content format has been retired.")
  end

  def send_for_generic_action(guide, button_text, &block)
    visit_edition guide
    action_button = page.find_link button_text
    action_element_id = "##{path_segment(action_button['href'])}"

    click_on button_text

    # Forces the driver to wait for any async javascript to complete
    page.has_css?('.modal-header')

    within :css, action_element_id, &block

    assert page.has_content?("updated"), "new page doesn't show 'updated' message"
    guide.reload
  end

  def send_for_fact_check(guide)
    button_text = 'Fact check'
    email = 'test@example.com'
    message = 'Let us know what you think'

    send_for_generic_action(guide, button_text) do
      fill_in "Email", with: email
      fill_in "Customised message", with: message
      click_on "Send"
    end
  end

  def send_action(guide, button_text, modal_button_text, message)
    send_for_generic_action(guide, button_text) do
      fill_in "Comment", with: message
      within :css, '.modal-footer' do
        click_on modal_button_text
      end
    end
  end

  def path_segment(url)
    url.split('#').last
  end

  def filter_for_all_users
    visit "/"
    within :css, ".user-filter-form" do
      select "All", from: 'user_filter'
      click_on "Filter publications"
    end
    assert page.has_content?("Publications")
  end

  def view_filtered_list(filter_label)
    visit "/"
    filter_link = find(:xpath, "//a[contains(., '#{filter_label}')]")
    assert_not filter_link.nil?, "Tab link #{filter_label} not found"
    assert_not filter_link['href'].nil?, "Tab link #{filter_label} has no target"

    filter_link.click

    assert page.has_content?(filter_label)
  end
end
