require "legacy_integration_test_helper"

class EditionScheduledPublishingTest < LegacyJavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    # queue up the edition, don't perform inline
    Sidekiq::Testing.fake!

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_publications_filter, false)
    test_strategy.switch!(:design_system_edit_phase_1, false)
    test_strategy.switch!(:design_system_edit_phase_2, false)
    test_strategy.switch!(:design_system_edit_phase_3a, false)
  end

  teardown do
    Sidekiq::Testing.inline!
  end

  test "should schedule publishing of an edition" do
    edition = FactoryBot.create(:edition, state: "ready", assigned_to: @author)
    visit_edition edition
    click_on "Schedule"

    tomorrow = Date.tomorrow
    year = tomorrow.year.to_s
    month = tomorrow.strftime("%b")
    day = tomorrow.day.to_s

    within "#schedule_for_publishing_form" do
      fill_in "Comment", with: "schedule!"

      select year, from: "edition_activity_schedule_for_publishing_attributes_publish_at_1i"
      select month, from: "edition_activity_schedule_for_publishing_attributes_publish_at_2i"
      select day, from: "edition_activity_schedule_for_publishing_attributes_publish_at_3i"
      select "12", from: "edition_activity_schedule_for_publishing_attributes_publish_at_4i"
      select "15", from: "edition_activity_schedule_for_publishing_attributes_publish_at_5i"
      click_on "Schedule for publishing"
    end
    assert page.has_content?("edition was successfully updated", exact: false)

    visit_editions
    within(:css, "div.sidebar-nav li.scheduled_for_publishing") do
      assert page.has_link?("Scheduled")
      assert page.has_content?("1")

      click_on "Scheduled"
    end

    # only one scheduled edition
    assert page.has_css? "#publication-list-container table tbody tr", count: 1

    edition.reload
    assert page.has_content? edition.title
    assert page.has_content?("12:15pm, #{day} #{month} #{year}"), "Scheduled time is not showing-up as expected"
  end

  test "should allow a scheduled edition to be published now" do
    edition = FactoryBot.create(:edition, :scheduled_for_publishing)
    stub_register_published_content

    visit_edition edition
    assert page.has_css?(".label", text: "Scheduled for publishing on #{edition.publish_at.strftime('%d/%m/%Y %H:%M')}")
    click_on "Publish now"

    within "#publish_form" do
      fill_in "Comment", with: "Go live now!"
      click_on "Send to publish"
    end

    assert page.has_css?(".label", text: "Published")
  end

  test "should cancel the publishing of a scheduled edition" do
    edition = FactoryBot.create(:edition, :scheduled_for_publishing)

    visit_edition edition
    assert page.has_css?(".label", text: "Scheduled for publishing on #{edition.publish_at.strftime('%d/%m/%Y %H:%M')}")
    click_on "Cancel scheduled publishing"

    within "#cancel_scheduled_publishing_form" do
      fill_in "Comment", with: "stop!"
      click_on "Cancel scheduled publishing"
    end

    assert page.has_css?(".label", text: "Ready")
  end
end
