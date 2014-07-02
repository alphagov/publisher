require 'integration_test_helper'

class EditionScheduledPublishingTest < JavascriptIntegrationTest

  def setup
    setup_users
    # queue up the edition, don't perform inline
    Sidekiq::Testing.fake!
  end

  def teardown
    Sidekiq::Testing.inline!
  end

  test "should schedule publishing of an edition" do
    edition = FactoryGirl.create(:edition, state: 'ready', :assigned_to => @author)
    visit_edition edition

    click_on "Schedule"

    within "#schedule_for_publishing_form" do
      fill_in "Comment", with: "schedule!"

      tomorrow = Date.tomorrow
      fill_in "publish_at_year", with: tomorrow.year.to_s
      fill_in "publish_at_month", with: tomorrow.month.to_s
      fill_in "publish_at_day", with: tomorrow.day.to_s
      fill_in "publish_at_hour", with: '12'
      fill_in "publish_at_min", with: '15'
      click_on "Send"
    end

    visit_editions
    within(:css, "div.sidebar-nav li.scheduled_for_publishing") do
      assert page.has_link?('Scheduled')
      assert page.has_content?('1')

      click_on "Scheduled"
    end

    # only one scheduled edition
    assert page.has_css? "#publication-list-container table tbody tr", count: 1

    edition.reload
    assert page.has_content? edition.title
    assert page.has_content? edition.publish_at.strftime('%d/%m/%Y %H:%M')
  end

  test "should cancel the publishing of a scheduled edition" do
    edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

    visit_edition edition
    assert page.has_content?("Status: Scheduled for publishing on #{edition.publish_at.strftime('%d/%m/%Y %H:%M')}")
    click_on "Cancel scheduled publishing"

    within "#cancel_scheduled_publishing_form" do
      fill_in "Comment", with: "stop!"
      click_on "Send"
    end

    assert page.has_content?("Status: Ready")
  end

end
