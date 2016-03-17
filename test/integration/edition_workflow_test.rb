require 'integration_test_helper'

class EditionWorkflowTest < JavascriptIntegrationTest

  setup do
    panopticon_has_metadata("id" => '2356')
    stub_linkables
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  # Assign a guide to a user. The user parameter can be a User or a name
  def assign(guide, user)
    if user.is_a? User
      user = user.name
    end
    visit_edition guide

    select user, from: "Assigned to"
    save_edition_and_assert_success

    guide.reload
  end

  def send_for_generic_action(guide, button_text, &block)
    visit_edition guide
    action_button = page.find_link button_text

    click_on button_text

    # Forces the driver to wait for any async javascript to complete
    page.has_css?('.modal-header')

    within :css, action_button['href'], &block

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

  def submit_for_review(guide, options={message: "I think this is done"})
    send_action guide, "2nd pair of eyes", "Send to 2nd pair of eyes", "I think this is done"
  end

  def filter_for(user)
    visit "/"
    within :css, ".user-filter-form" do
      select "All", :from => 'user_filter'
      click_on "Filter publications"
    end
    assert page.has_content?("Publications")
  end

  def view_filtered_list(filter_label)
    visit "/"
    filter_link = find(:xpath, "//a[contains(., '#{filter_label}')]")
    refute filter_link.nil?, "Tab link #{filter_label} not found"
    refute filter_link['href'].nil?, "Tab link #{filter_label} has no target"

    filter_link.click

    assert page.has_content?(filter_label)
  end

  # Given a guide and an owner, take the guide to review stage
  def get_to_review(guide, owner)
    login_as owner
    assign guide, owner
    fill_in_parts guide
    submit_for_review guide
  end

  def get_to_fact_check_received(guide, owner)
    get_to_fact_check(guide, owner)
    receive_fact_check(User.new, guide)
    guide.reload
  end

  def get_to_fact_check(guide, owner)
    get_to_review guide, owner
    login_as "Bob"
    send_action guide, "OK for publication", "OK for publication", "Yup, looks good"
    send_for_fact_check guide
  end

  test "should show and update a guide's assigned person" do
    guide = FactoryGirl.create(:guide_edition)
    fill_in_parts guide
    assert_nil guide.assigned_to

    assign guide, "Bob"
    assert_equal guide.assigned_to, get_user("Bob")

    assign guide, "Charlie"
    assert_equal guide.assigned_to, get_user("Charlie")
  end

  test "can assign a new guide without editing the part" do
    guide = FactoryGirl.create(:guide_edition)

    assign guide, "Bob"
    assert_equal guide.assigned_to, get_user("Bob")
  end

  test "doesn't show disabled users in 'Assigned to' select box" do
    disabled_user = FactoryGirl.create(:disabled_user)
    guide = FactoryGirl.create(:guide_edition)

    visit_edition guide

    refute page.has_xpath?("//select[@id='edition_assigned_to_id']/option[text() = '#{disabled_user.name}']")
  end

  test "a guide is in draft after creation" do
    guide = FactoryGirl.create(:guide_edition)

    assign guide, "Alice"
    assert guide.draft?

    visit_edition guide
    assert page.has_css?('.label', text: 'Draft')
  end

  test "should update progress of a guide" do
    guide = FactoryGirl.create(:guide_edition)
    guide.update_attribute(:state, 'ready')
    fill_in_parts guide

    page.find_link('Fact check').trigger('click')

    within "#send_fact_check_form" do
      fill_in "Customised message", with: "Blah"
      fill_in "Email address", with: "user@example.com"
      click_on "Send"
    end

    assert page.has_css?('.label', text: 'Fact check')

    guide.reload

    assert guide.fact_check?
  end

  test "a guide in the ready state can be requested to make more amendments" do
    guide = FactoryGirl.create(:guide_edition)
    guide.update_attribute(:state, 'ready')
    fill_in_parts guide

    login_as "Bob"
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for "All"
    view_filtered_list "Amends needed"
    assert page.has_content? guide.title
  end

  test "a guide in the fact check state can be requested to make more amendments" do
    guide = FactoryGirl.create(:guide_edition)
    guide.update_attribute(:state, 'fact_check')
    fill_in_parts guide

    login_as "Bob"
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for "All"
    view_filtered_list "Amends needed"
    assert page.has_content? guide.title
  end

  test "can flag guide for review" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Alice"
    fill_in_parts guide
    submit_for_review guide

    login_as "Bob"
    filter_for "All"
    view_filtered_list "In review"

    assert page.has_content? guide.title
  end

  test "cannot review own guide" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Alice"
    fill_in_parts guide
    submit_for_review guide

    visit_edition guide
    assert page.has_selector?(".alert-info")
    refute has_link? "OK for publication"
  end

  test "cannot be the guide reviewer and assignee" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Bob"
    fill_in_parts guide
    submit_for_review guide

    visit_edition guide

    select("Bob", from: "Reviewer")

    save_edition_and_assert_error

    assert page.has_css?(".form-group.has-error li", text: "can't be the assignee")
  end

  test "can deselect the guide reviewer" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Bob"
    fill_in_parts guide
    submit_for_review guide

    visit_edition guide

    select("", from: "Reviewer")
    save_edition_and_assert_success
  end

  test "can unassign the guide" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Bob"
    fill_in_parts guide

    visit_edition guide

    assign guide, ""

    assert_nil guide.assignee
    assert page.has_select?("Assigned to", selected: "")
  end

  test "can become the guide reviewer" do
    guide = FactoryGirl.create(:guide_edition)
    login_as "Alice"

    assign guide, "Bob"
    fill_in_parts guide
    submit_for_review guide

    visit_edition guide

    select("Charlie", from: "Reviewer")
    save_edition_and_assert_success
  end

  test "can review another's guide" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_review guide, "Alice"

    login_as "Bob"
    visit_edition guide
    assert page.has_selector?(".alert-info")
    assert has_link? "Needs more work"
    assert has_link? "OK for publication"
  end

  test "review failed" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_review guide, "Alice"

    login_as "Bob"
    send_action guide, "Needs more work", "Request amendments", "You need to fix some stuff"
    filter_for "All"
    view_filtered_list "Amends needed"
    assert page.has_content? guide.title
  end

  test "review passed" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_review guide, "Alice"

    login_as "Bob"
    send_action guide, "OK for publication", "OK for publication", "Yup, looks good"
    filter_for "All"
    view_filtered_list "Ready"
    assert page.has_content? guide.title
  end

  test "can skip fact check" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_fact_check guide, "Alice"
    visit_edition guide

    click_on "Admin"
    click_on "Skip fact check"

    # This information is not quite correct but it is the current behaviour.
    # Adding this test as an aid to future improvements
    assert page.has_content? "Fact check was skipped for this edition."

    filter_for "All"
    view_filtered_list "Ready"
    assert page.has_content? guide.title
    visit_edition guide
    assert page.has_content? "Request this edition to be amended further."
    assert page.has_content? "Needs more work"
  end

  test "can progress from fact check" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_fact_check_received guide, "Alice"
    visit_edition guide
    send_action guide, "Minor or no changes required", "Approve fact check", "Hurrah!"
    filter_for "All"
    view_filtered_list "Ready"
    assert page.has_content? guide.title
  end

  test "can go back to fact check from fact check received" do
    guide = FactoryGirl.create(:guide_edition)
    get_to_fact_check_received guide, "Alice"

    send_for_fact_check guide

    visit_edition guide
    assert page.has_css?('.label', text: 'Fact check')
  end

  test "can create a new edition from the listings screens" do
    guide = FactoryGirl.create(:guide_edition, state: 'published')
    filter_for "All"
    view_filtered_list "Published"
    click_on "Create new edition"
    assert page.has_content? "New edition created"
  end

  test "should link to a newer sibling" do
    artefact = FactoryGirl.create(:artefact)
    old_edition = FactoryGirl.create(
      :guide_edition,
      panopticon_id: artefact.id,
      state: "published",
      version_number: 1
    )
    new_edition = FactoryGirl.create(
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
    guide = FactoryGirl.create(:guide_edition, state: 'published')
    filter_for "All"
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
end
