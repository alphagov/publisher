require 'integration_test_helper'

class EditionWorkflowTest < ActionDispatch::IntegrationTest

  setup do
    panopticon_has_metadata("id" => '2356')
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  # Get a single user by their name. If the user doesn't exist, return nil.
  def get_user(name)
    User.where(name: name).first
  end

  # Set the given user to be the current user
  # Accepts either a User object or a user's name
  def login_as(user)
    if not user.is_a? User
      user = get_user(user)
    end
    GDS::SSO.test_user = user
    Capybara.current_session.driver.browser.clear_cookies
  end

  def visit_guide(guide)
    visit "/admin/editions/#{guide.to_param}"
  end

  # Assign a guide to a user. The user parameter can be a User or a name
  def assign(guide, user)
    if user.is_a? User
      user = user.name
    end
    visit_guide guide

    select user, from: "Assigned to"
    click_on "Save"

    wait_until { page.has_content? "successfully updated" }
    guide.reload
  end

  # Transfer a guide from lined-up state to draft state
  def start_work_on(guide)
    visit "/admin"
    click_on "Lined up"
    wait_until { page.has_content? guide.title }
    within :xpath, "//form[contains(@action, '#{guide.id}/start_work')]" do
      click_on "Start work"
    end
    wait_until { page.has_content? "Work started" }
  end

  # Fill in some sample sections for a guide
  def fill_in_parts(guide)
    visit_guide guide

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
  end

  def button_selector(text)
    "//button[text()='#{text}']"
  end

  def find_button(text)
    find(:xpath, button_selector(text))
  end

  def has_button(text)
    page.has_xpath? button_selector(text)
  end

  def send_action(guide, button_text, message)
    visit_guide guide
    action_button = find_button button_text

    assert (not action_button['disabled'])
    action_button.click

    within action_button['href'] do
      fill_in "Comment", with: message
      click_on "Send"
    end

    wait_until { page.has_content? "updated" }
    guide.reload
  end

  def submit_for_review(guide, options={message: "I think this is done"})
    send_action guide, "2nd pair of eyes", "I think this is done"
  end

  def filter_for(user)
    visit "/admin"
    select "All", :from => 'filter'
    click_button "Filter"
    wait_until { page.has_content? "All publications" }
  end

  def view_tab(tab_name)
    visit "/admin"
    tab_link = find(:xpath, "//a[contains(., '#{tab_name}')]")
    assert (not tab_link.nil?), "Tab link #{tab_name} not found"
    assert (not tab_link['href'].nil?), "Tab link #{tab_name} has no target"

    # puts "Found tab link with URL '#{tab_link['href']}' and text '#{tab_link.text}'"
    # puts "Tab link: #{tab_link.inspect}"

    tab_link.click

    # If the JavaScript is working happily, the link's target gets rewritten to
    # a target tab, and the table will be loaded in as a child of this target.
    # If the JavaScript is broken in some way, the table will just be loaded in
    # a new page, so we can safely look for a table with a class of 'formats',
    # which we can't safely do when the JavaScript works, because there can be
    # several such tables on the page.
    if tab_link['href'].starts_with? '#'
      expected_selector = "#{tab_link['href']} table"
    else
      puts 'WARNING: the tab JavaScript on this page is b0rked'
      expected_selector = 'table.formats'
    end

    wait_until { page.has_selector? expected_selector }
  end

  # Given a guide and an owner, take the guide to review stage
  def get_to_review(guide, owner)
    login_as owner
    assign guide, owner
    start_work_on guide
    fill_in_parts guide
    submit_for_review guide
  end

  test "should show and update a guide's assigned person" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    fill_in_parts guide
    assert_nil guide.assigned_to

    assign guide, "Bob"
    assert_equal guide.assigned_to, get_user("Bob")

    assign guide, "Charlie"
    assert_equal guide.assigned_to, get_user("Charlie")
  end

  test "can assign a new guide without editing the part" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)

    assign guide, "Bob"
    assert_equal guide.assigned_to, get_user("Bob")
  end

  test "a guide is lined up until work starts on it" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)

    assign guide, "Alice"
    assert guide.lined_up?

    visit "/admin"
    click_on "Lined up"
    click_on "Start work"
    wait_until { page.has_content? "Work started" }
    guide.reload
    assert !guide.lined_up?
  end

  test "should update progress of a guide" do

    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    guide.update_attribute(:state, 'ready')
    fill_in_parts guide

    click_on "Fact check"

    within "#send_fact_check_form" do
      fill_in "Comment",       with: "Blah"
      fill_in "Email address", with: "user@example.com"
      click_on "Send"
    end

    wait_until { page.has_content? "Status: Fact check" }

    guide.reload

    assert guide.fact_check?
  end

  test "can flag guide for review" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    login_as "Alice"

    assign guide, "Alice"
    start_work_on guide
    fill_in_parts guide
    submit_for_review guide

    login_as "Bob"
    filter_for "All"
    view_tab "In review"

    assert page.has_content? guide.title
  end

  test "cannot review own guide" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    login_as "Alice"

    assign guide, "Alice"
    start_work_on guide
    fill_in_parts guide
    submit_for_review guide

    visit_guide guide
    wait_until { page.has_selector? ".alert-info" }
    assert (not has_button? "OK for publication")
  end

  test "can review another's guide" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    get_to_review guide, "Alice"

    login_as "Bob"
    visit_guide guide
    wait_until { page.has_selector? ".alert-info" }
    assert has_button? "Needs more work"
    assert has_button? "OK for publication"
  end

  test "review failed" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    get_to_review guide, "Alice"

    login_as "Bob"
    send_action guide, "Needs more work", "You need to fix some stuff"
    filter_for "All"
    view_tab "Amends needed"
    assert page.has_content? guide.title
  end

  test "review passed" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    get_to_review guide, "Alice"

    login_as "Bob"
    send_action guide, "OK for publication", "Yup, looks good"
    filter_for "All"
    view_tab "Ready"
    assert page.has_content? guide.title
  end

end
