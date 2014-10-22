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
      select tomorrow.year.to_s, from: "edition_activity_schedule_for_publishing_attributes_publish_at_1i"
      select tomorrow.strftime("%B"), from: "edition_activity_schedule_for_publishing_attributes_publish_at_2i"
      select tomorrow.day.to_s, from: "edition_activity_schedule_for_publishing_attributes_publish_at_3i"
      select '12', from: "edition_activity_schedule_for_publishing_attributes_publish_at_4i"
      select '15', from: "edition_activity_schedule_for_publishing_attributes_publish_at_5i"
      click_on "Schedule for publishing"
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
    assert page.has_content? edition.publish_at.to_s(:govuk_date_short)
  end

  test "should allow a scheduled edition to be published now" do
    edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
    stub_artefact_registration(edition.slug)

    visit_edition edition
    assert page.has_content?("Status: Scheduled for publishing on #{edition.publish_at.strftime('%d/%m/%Y %H:%M')}")
    click_on "Publish now"

    within "#publish_form" do
      fill_in "Comment", with: "Go live now!"
      click_on "Send to publish"
    end

    assert page.has_content?("Status: Published")
  end

  test "should cancel the publishing of a scheduled edition" do
    edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

    visit_edition edition
    assert page.has_content?("Status: Scheduled for publishing on #{edition.publish_at.strftime('%d/%m/%Y %H:%M')}")
    click_on "Cancel scheduled publishing"

    within "#cancel_scheduled_publishing_form" do
      fill_in "Comment", with: "stop!"
      click_on "Cancel scheduled publishing"
    end

    assert page.has_content?("Status: Ready")
  end

end
