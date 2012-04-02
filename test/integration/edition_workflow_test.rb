require 'integration_test_helper'

class EditionWorkflowTest < ActionDispatch::IntegrationTest

  setup do
    panopticon_has_metadata("id" => '2356')
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
  end

  # Get a single user by their name. If the user doesn't exist, return nil.
  def get_user(name)
    User.where(name: name).first
  end

  test "should show and update a guide's assigned person" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)

    visit "/admin/editions/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_nil guide.assigned_to

    select "Bob", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal guide.assigned_to, get_user("Bob")

    select "Charlie", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal guide.assigned_to, get_user("Charlie")
  end

  test "can assign a new guide without editing the part" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)

    visit "/admin/editions/#{guide.to_param}"

    select "Bob", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal guide.assigned_to, get_user("Bob")
  end

  test "a guide is lined up until work starts on it" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)

    visit "/admin/editions/#{guide.to_param}"

    select "Alice", from: "Assigned to"
    click_on "Save"

    wait_until { page.has_content? "successfully updated" }
    guide.reload
    assert guide.lined_up?

    visit "/admin"
    click_on "Lined up (1)"
    click_on "Start work"
    wait_until { page.has_content? "Work started" }
    guide.reload
    assert !guide.lined_up?
  end

  test "should update progress of a guide" do

    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    guide.update_attribute(:state, 'ready')

    visit "/admin/editions/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"

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
end
