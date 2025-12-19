require "legacy_integration_test_helper"
require "gds_api/test_helpers/calendars"

class EditionWorkflowTest < LegacyJavascriptIntegrationTest
  include GdsApi::TestHelpers::Calendars
  attr_reader :alice, :bob, :guide

  setup do
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)

    @alice = FactoryBot.create(:user, :govuk_editor, name: "Alice")
    @bob = FactoryBot.create(:user, :govuk_editor, name: "Bob")
    @welsh_editor = FactoryBot.create(:user, :welsh_editor, name: "WelshEditor")

    @guide = FactoryBot.create(:guide_edition)
    login_as "Alice"
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "should show and update a guide's assigned person" do
    assert_nil guide.assigned_to

    visit_edition guide
    select2 "Bob", from: "Assigned to"
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
    today = Date.parse("2017-04-28")
    stub_calendars_has_a_bank_holiday_on(Date.parse("2017-05-01"), in_division: "england-and-wales")

    Timecop.freeze(today) do
      guide.update!(state: "ready")
      visit_edition guide

      click_link("Fact check")

      within "#send_fact_check_form" do
        customised_message = page.find_field("Customised message")
        assert customised_message
        assert customised_message.value.include? "Deadline: 8 May 2017 (5 working days from today - 28 April 2017)"
      end
    end
  end

  test "fact-check email has ID in it" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Email address", with: "user@example.com"
      click_on "Send to Fact check"
    end
    assert page.has_content?("Guide updated")

    fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user@example.com" }.last
    assert fact_check_email
    assert_match(/Do not remove \[.+?\] from the subject line/, fact_check_email.body.to_s)
  end

  test "fact-check email has reply-to address in it" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Email address", with: "user@example.com"
      click_on "Send to Fact check"
    end
    assert page.has_content?("Guide updated")

    fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user@example.com" }.last
    assert fact_check_email
    assert_match(/reply is being sent to #{Regexp.escape guide.fact_check_email_address}\./, fact_check_email.body.to_s)
  end

  test "can send guide to fact-check when in ready state" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user@example.com"
      click_on "Send"
    end

    assert page.has_css?(".label", text: "Fact check")

    click_on "History and notes"
    assert page.has_content? "Send fact check by Alice"
    assert page.has_content? "Request sent to user@example.com"

    guide.reload
    assert guide.fact_check?

    fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user@example.com" }.last
    assert fact_check_email
    assert_match(/‘\[#{guide.title}\]’ GOV.UK preview of new edition \[[a-z0-9-]+\]/, fact_check_email.subject)
    assert_equal "Blah", fact_check_email.body.to_s
  end

  test "can send guide to several fact-check recipients with comma separated emails" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    ActionMailer::Base.deliveries.clear

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1@example.com, user2@example.com"
      click_on "Send"
    end

    assert page.has_css?(".label", text: "Fact check")
    guide.reload
    assert guide.fact_check?

    fact_check_email1 = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user1@example.com" }.last
    assert fact_check_email1
    fact_check_email2 = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user2@example.com" }.last
    assert fact_check_email2
    assert_match(/‘\[#{guide.title}\]’ GOV.UK preview of new edition \[[a-z0-9-]+\]/, fact_check_email1.subject)
    assert_match(/‘\[#{guide.title}\]’ GOV.UK preview of new edition \[[a-z0-9-]+\]/, fact_check_email2.subject)
    assert_equal "Blah", fact_check_email1.body.to_s
    assert_equal "Blah", fact_check_email2.body.to_s
  end

  test "the fact-check form validates emails and won't send if they are mangled" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1"
      click_on "Send"
    end

    assert page.has_content? "The email addresses you entered appear to be invalid."
    guide.reload
    assert_not guide.fact_check?

    click_link("Fact check")

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1@example.com user2@example.com"
      click_on "Send"
    end

    assert page.has_content? "The email addresses you entered appear to be invalid."
    guide.reload
    assert_not guide.fact_check?

    click_link("Fact check")

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user1, user2@example.com"
      click_on "Send"
    end

    assert page.has_content? "The email addresses you entered appear to be invalid."
    guide.reload
    assert_not guide.fact_check?
  end

  test "a guide in the ready state can be requested to make more amendments" do
    guide.update!(state: "ready")

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "a guide in the fact-check state can be requested to make more amendments" do
    guide.update!(state: "fact_check")

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "a guide in the fact-check state can resend the email" do
    guide.update!(state: "ready")
    visit_edition guide

    click_link("Fact check")

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah blah fact check message"
      fill_in "Email address", with: "user-to-ask-for-fact-check@example.com"
      click_on "Send"
    end

    ActionMailer::Base.deliveries.clear

    visit_edition guide
    send_for_generic_action guide, "Resend fact check email" do
      assert page.has_content? "Blah blah fact check message"
      assert page.has_content? "user-to-ask-for-fact-check@example.com"
      click_on "Resend"
    end
    assert page.has_content?("updated")

    visit_edition guide
    click_on "History and notes"
    assert page.has_content? "Resend fact check by Alice"

    resent_fact_check_email = ActionMailer::Base.deliveries.select { |mail| mail.to.include? "user-to-ask-for-fact-check@example.com" }.last
    assert resent_fact_check_email
    assert_match(/‘\[#{guide.title}\]’ GOV.UK preview of new edition \[[a-z0-9-]+\]/, resent_fact_check_email.subject)
    assert_equal "Blah blah fact check message", resent_fact_check_email.body.to_s
  end

  test "sending a fact check email to a non-permitted address will return an error" do
    raises_exception = lambda { |_request, _params|
      response = Minitest::Mock.new
      response.expect :code, 400
      response.expect :body, "Can't send to this recipient using a team-only API key"
      raise Notifications::Client::BadRequestError, response
    }

    EventMailer.stub(:request_fact_check, raises_exception) do
      guide.update!(state: "ready")
      visit_edition guide

      click_link("Fact check")

      within "#send_fact_check_form" do
        fill_in "Customised message", with: "Blah blah fact check message"
        fill_in "Email address", with: "user-to-ask-for-fact-check@example.com"
        click_on "Send"
      end

      assert page.has_content? "Error: One or more recipients not in GOV.UK Notify team (code: 400).\nThis error will not occur in Production."
    end
  end

  test "can flag guide for review" do
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "In review"

    assert page.has_content? guide.title
  end

  test "cannot review own guide" do
    guide.assigned_to = alice

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
    assert page.has_content?("updated")

    assert page.has_selector?(".alert-info")
    assert has_no_link? "No changes needed"
  end

  test "cannot be the guide reviewer and assignee" do
    guide.assigned_to = bob
    guide.state = "in_review"
    guide.save!(validate: false)

    visit_edition guide
    select2 "Bob", css: "#s2id_edition_reviewer"
    save_edition_and_assert_error("can't be the assignee", "#edition_reviewer")
  end

  test "can deselect the guide reviewer" do
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
    assert page.has_content?("updated")

    select2_clear css: "#s2id_edition_reviewer"
    save_edition_and_assert_success
  end

  test "can unassign the guide" do
    guide.assigned_to = bob

    visit_edition guide
    select2_clear css: "#s2id_edition_assigned_to_id"
    save_edition_and_assert_success
    guide.reload

    assert_nil guide.assignee
    page.assert_selector("select#edition_assigned_to_id", text: "", visible: false)
  end

  test "can become the guide reviewer" do
    guide.assigned_to = bob

    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
    assert page.has_content?("updated")

    visit_edition guide

    select2 "Alice", css: "#s2id_edition_reviewer"
    save_edition_and_assert_success
  end

  test "can review another's guide" do
    guide.state = "in_review"
    guide.save!(validate: false)
    guide.assigned_to = bob

    visit_edition guide
    assert page.has_selector?(".alert-info")
    assert has_link? "Needs more work"
    assert has_link? "No changes needed"
  end

  test "review failed" do
    guide.state = "in_review"
    guide.save!(validate: false)
    guide.assigned_to = bob

    visit_edition guide
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "Amends needed"

    assert page.has_content? guide.title
  end

  test "review passed" do
    guide.state = "in_review"
    guide.save!(validate: false)

    visit_edition guide
    send_action guide, "No changes needed", "No changes needed", "Yup, looks good"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "Ready"
    assert page.has_content? guide.title
  end

  test "can skip fact-check" do
    guide.update!(state: "fact_check")

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
    guide.update!(state: "fact_check_received")

    visit_edition guide
    send_action guide, "No more work needed", "Approve fact check", "Hurrah!"
    assert page.has_content?("updated")

    filter_for_all_users
    view_filtered_list "Ready"

    assert page.has_content? guide.title
  end

  test "can go back to fact-check from fact-check received" do
    guide.update!(state: "fact_check_received")

    visit_edition guide
    send_for_fact_check guide
    visit_edition guide

    assert page.has_css?(".label", text: "Fact check")
  end

  test "can create a new edition from the listings screens" do
    guide.update!(state: "published")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"
    click_on "Create new edition"

    assert page.has_content? "New edition created"
  end

  test "Welsh editors cannot create a new edition from the listings screen" do
    guide.update!(state: "published")
    login_as("WelshEditor")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"
    assert page.has_no_content? "Create new edition"
  end

  test "Welsh editors can create a new Welsh edition from the listings screen" do
    guide.update!(state: "published")
    guide.artefact.update!(language: "cy")
    login_as("WelshEditor")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"
    click_on "Create new edition"

    assert page.has_content? "New edition created"
  end

  test "Welsh editors cannot edit a newer edition from the listings screen" do
    guide.update!(state: "published")
    visit "/"
    filter_for_all_users
    view_filtered_list "Published"
    click_on "Create new edition"
    assert page.has_content? "New edition created"

    login_as("WelshEditor")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"

    assert page.has_no_content? "Edit newer edition"
  end

  test "Welsh editors can edit a newer Welsh edition from the listings screen" do
    guide.update!(state: "published")
    guide.artefact.update!(language: "cy")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"
    click_on "Create new edition"

    login_as("WelshEditor")

    visit "/"
    filter_for_all_users
    view_filtered_list "Published"

    click_on "Edit newer edition"

    assert_equal page.current_path, edition_path(guide.artefact.latest_edition)
  end

  test "Welsh editors cannot create new editions from the edition page" do
    guide.update!(state: "published")
    login_as("WelshEditor")

    visit edition_path(guide)
    assert page.has_no_content? "Create new edition"
  end

  test "Welsh editors can create new Welsh editions from the edition page" do
    guide.update!(state: "published")
    guide.artefact.update!(language: "cy")
    login_as("WelshEditor")

    visit edition_path(guide)
    click_on "Create new edition"

    assert page.has_content? "New edition created"
  end

  test "Welsh editors cannot edit existing newer editions from the edition page" do
    guide.update!(state: "published")
    visit edition_path(guide)
    click_on "Create new edition"

    login_as("WelshEditor")
    visit edition_path(guide)

    assert page.has_no_content? "Edit existing newer edition"
  end

  test "Welsh editors can edit existing newer Welsh editions from the edition page" do
    guide.update!(state: "published")
    guide.artefact.update!(language: "cy")

    visit edition_path(guide)
    click_on "Create new edition"

    login_as("WelshEditor")
    visit edition_path(guide)

    click_on "Edit existing newer edition"

    assert_equal page.current_path, edition_path(guide.artefact.latest_edition)
  end

  test "Welsh editors cannot update editions" do
    login_as("WelshEditor")
    visit edition_path(guide)

    assert page.has_no_content? "Save"
  end

  test "Welsh editors can update Welsh editions" do
    guide.artefact.update!(language: "cy")

    login_as("WelshEditor")
    visit edition_path(guide)

    fill_in "Title", with: "Updated Welsh Title"

    save_edition_and_assert_success
  end

  test "Welsh editors can assign users to Welsh editions" do
    guide.artefact.update!(language: "cy")

    login_as("WelshEditor")
    visit edition_path(guide)

    select2 "Bob", from: "Assigned to"
    save_edition_and_assert_success
    guide.reload

    assert_equal bob, guide.assigned_to

    save_edition_and_assert_success
  end

  test "Welsh editors cannot assign users to non-Welsh editions" do
    login_as("WelshEditor")
    visit edition_path(guide)

    assert page.has_no_content? "Assigned to"
  end

  test "Welsh editors may not see buttons to respond to fact checks" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :fact_check_received)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_content?("We have received a fact check response for this edition")
    assert_not page.has_css?(".btn.btn-info", text: "Needs more work")
    assert_not page.has_css?(".btn.btn-info", text: "No more work needed")
  end

  test "Welsh editors may see buttons to respond to fact checks for Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :fact_check_received, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_content?("We have received a fact check response for this edition")
    assert page.has_css?(".btn.btn-info", text: "Needs more work")
    assert page.has_css?(".btn.btn-info", text: "No more work needed")
  end

  test "Welsh editors may not request more work for fact checked edition" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :fact_check)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_content?("We’re awaiting a response")
    assert_not page.has_css?(".btn.btn-info", text: "Needs more work")
  end

  test "Welsh editors may request more work for fact checked Welsh edition" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :fact_check, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_content?("We’re awaiting a response")
    assert page.has_css?(".btn.btn-info", text: "Needs more work")
  end

  test "Welsh editors may not request more work for 'ready' non-Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :ready)
    login_as("WelshEditor")

    visit_edition edition

    assert_not page.has_content?("Request this edition to be amended further.")
    assert_not page.has_css?(".btn.btn-info", text: "Needs more work")
  end

  test "Welsh editors may request more work for 'ready' Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :ready, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_content?("Request this edition to be amended further.")
    assert page.has_css?(".btn.btn-info", text: "Needs more work")
  end

  test "Welsh editors cannot see publishing buttons for non-Welsh 'ready' editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :ready, panopticon_id: FactoryBot.create(:artefact).id)
    login_as("WelshEditor")

    visit_edition edition

    assert_not page.has_css?(".btn.btn-large.btn-warning", text: "Schedule")
    assert_not page.has_css?(".btn.btn-large.btn-primary", text: "Publish")
  end

  test "Welsh editors can see publishing buttons for Welsh 'ready' editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :ready, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_css?(".btn.btn-large.btn-warning", text: "Schedule")
    assert page.has_css?(".btn.btn-large.btn-primary", text: "Publish")
  end

  test "Welsh editors cannot see publishing buttons for non-Welsh 'scheduled' editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :scheduled_for_publishing, panopticon_id: FactoryBot.create(:artefact).id)
    login_as("WelshEditor")

    visit_edition edition

    assert_not page.has_css?(".btn.btn-large.btn-warning", text: "Cancel scheduled publishing")
    assert_not page.has_css?(".btn.btn-large.btn-primary", text: "Publish now")
  end

  test "Welsh editors can see publishing buttons for Welsh 'scheduled' editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :scheduled_for_publishing, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_css?(".btn.btn-large.btn-danger", text: "Cancel scheduled publishing")
    assert page.has_css?(".btn.btn-large.btn-primary", text: "Publish now")
  end

  test "Welsh editors cannot see review buttons for non-Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :in_review, panopticon_id: FactoryBot.create(:artefact).id)
    login_as("WelshEditor")

    visit_edition edition

    assert_not page.has_link?("Needs more work", href: "#request_amendments_form")
    assert_not page.has_link?("No changes needed", href: "#approve_review_form")
  end

  test "Welsh editors can see review buttons for Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :in_review, :welsh)
    login_as("WelshEditor")

    visit_edition edition

    assert page.has_link?("Needs more work", href: "#request_amendments_form")
    assert page.has_link?("No changes needed", href: "#approve_review_form")
  end

  test "Welsh editors cannot see buttons to request a review for non-Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :draft, panopticon_id: FactoryBot.create(:artefact).id)
    login_as("WelshEditor")

    visit_edition edition

    assert_not page.has_link?("2nd pair of eyes", href: "#request_review_form")
  end

  test "Welsh editors can see buttons to request a review for Welsh editions" do
    edition = FactoryBot.create(:simple_smart_answer_edition, :draft, :welsh)
    login_as("WelshEditor")

    visit_edition edition
    find_link("2nd pair of eyes", href: "#request_review_form").click

    assert page.has_button?("Send to 2nd pair of eyes", type: "submit")
  end

  test "can preview a draft article on draft-origin" do
    guide.update!(state: "draft")

    visit_edition guide
    assert page.has_text?("Preview")
  end

  test "can view a published article on the live site" do
    guide.update!(state: "published")

    visit_edition guide
    assert page.has_text?("View this on the GOV.UK website")
  end

  test "cannot preview an archived article" do
    guide.update!(state: "archived")

    visit_edition guide
    assert page.has_css?("#edit div div.navbar.navbar-inverse.navbar-fixed-bottom.text-center div div div a:nth-child(2)", text: "Preview")
  end

  test "should link to a newer sibling" do
    artefact = FactoryBot.create(:artefact)
    old_edition = FactoryBot.create(
      :guide_edition,
      panopticon_id: artefact.id,
      state: "published",
      version_number: 1,
    )
    new_edition = FactoryBot.create(
      :guide_edition,
      panopticon_id: artefact.id,
      state: "draft",
      version_number: 2,
    )
    visit_edition old_edition
    assert page.has_link?(
      "Edit existing newer edition",
      href: edition_path(new_edition),
    ),
           "Page should have edit link"
  end

  test "should show an alert if another person has created a newer edition" do
    guide.update!(state: "published")

    filter_for_all_users
    view_filtered_list "Published"

    # Simulate that someone has clicked on 'Create new edition'
    # while current user has been viewing the list of published editions
    new_edition = guide.build_clone(GuideEdition)
    new_edition.save!

    # Current user now decides to click the button
    click_on "Create new edition"

    assert page.has_content?("Another person has created a newer edition")
    assert page.has_css?(".label", text: "Published")
  end

  def send_for_generic_action(guide, button_text, &block)
    visit_edition guide
    action_button = page.find_link button_text
    action_element_id = "##{path_segment(action_button['href'])}"

    click_on button_text

    # Forces the driver to wait for any async javascript to complete
    page.has_css?(".modal-header")

    within :css, action_element_id, &block

    guide.reload
  end

  def send_for_fact_check(guide)
    button_text = "Fact check"
    email = "test@example.com"
    message = "Let us know what you think"

    send_for_generic_action(guide, button_text) do
      fill_in "Email", with: email
      fill_in "Customised message", with: message
      click_on "Send to Fact check"
    end
    assert page.has_content?("updated")
  end

  def send_action(guide, button_text, modal_button_text, message)
    send_for_generic_action(guide, button_text) do
      fill_in "Comment", with: message
      within :css, ".modal-footer" do
        click_on modal_button_text
      end
    end
  end

  def path_segment(url)
    url.split("#").last
  end

  def filter_for_all_users
    visit "/"
    within :css, ".user-filter-form" do
      select2 "All", from: "ASSIGNEE"
      click_on "Filter publications"
    end
    assert page.has_content?("Publications")
  end

  def view_filtered_list(filter_label)
    visit "/"
    filter_link = find(:xpath, "//a[contains(., '#{filter_label}')]")
    assert_not filter_link.nil?, "Tab link #{filter_label} not found"
    assert_not filter_link["href"].nil?, "Tab link #{filter_label} has no target"

    filter_link.click

    assert page.has_content?(filter_label)
  end
end
