require 'integration_test_helper'

class GuideAssignmentTest < ActionDispatch::IntegrationTest

  test "should show and update a guide's assigned person" do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/2356.js").
      to_return(status: 200, body: "{}", headers: {})

    # This isn't right, really need a way to run actions when
    # logged in as particular users without having Signonotron running.
    #
    alice   = FactoryGirl.create(:user)

    bob     = FactoryGirl.create(:user, name: "Bob")
    charlie = FactoryGirl.create(:user, name: "Charlie")

    guide = FactoryGirl.create(:guide, panopticon_id: 2356)

    visit "/admin/guides/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_nil guide.editions.last.assigned_to

    select "Bob", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal bob, guide.editions.last.assigned_to

    select "Charlie", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal charlie, guide.editions.last.assigned_to
  end

  test "can assign a new guide without editing the part" do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/2356.js").
      to_return(status: 200, body: "{}", headers: {})

    # This isn't right, really need a way to run actions when
    # logged in as particular users without having Signonotron running.
    #
    alice   = FactoryGirl.create(:user)

    bob     = FactoryGirl.create(:user, name: "Bob")
    charlie = FactoryGirl.create(:user, name: "Charlie")

    guide = FactoryGirl.create(:guide, panopticon_id: 2356)

    visit "/admin/guides/#{guide.to_param}"

    select "Bob", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
    assert_equal bob, guide.editions.last.assigned_to
  end

  test "a guide is lined up until work starts on it" do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/2356.js").
      to_return(status: 200, body: "{}", headers: {})

    alice   = FactoryGirl.create(:user, name: "Alice")

    guide = FactoryGirl.create(:guide, panopticon_id: 2356)

    visit "/admin/guides/#{guide.to_param}"

    select "Alice", from: "Assigned to"
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }
    guide.reload
    assert guide.has_lined_up?

    visit "/admin"
    click_on "Start work"
    wait_until { page.has_content? "Work started" }
    guide.reload
    assert !guide.has_lined_up?
  end
end

