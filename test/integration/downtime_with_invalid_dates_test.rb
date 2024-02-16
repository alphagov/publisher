require "integration_test_helper"

class DowntimeWithInvalidDates < ActionDispatch::IntegrationTest
  setup do
    setup_users

    @edition = FactoryBot.create(
      :transaction_edition,
      :published,
      title: "Apply to become a driving instructor",
      slug: "apply-to-become-a-driving-instructor",
    )

    WebMock.reset!
    stub_any_publishing_api_put_content
    stub_any_publishing_api_publish

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:design_system_downtime_index_page, true)
    test_strategy.switch!(:design_system_downtime_new, true)
  end

  test "Scheduling new downtime with invalid dates" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)

    visit root_path
    click_link "Downtime"
    click_link "Add downtime"

    enter_from_date_and_time 1.day.ago
    enter_to_date_and_time 1.day.ago - 1.day

    click_button "Save"

    assert page.has_link?("End time must be in the future", href: "#downtime_end_time")
    assert page.has_link?("Start time must be earlier than end time", href: "#downtime_start_time")
  end

  def enter_from_date_and_time(start_time)
    enter_date_and_time("start", start_time)
  end

  def enter_to_date_and_time(end_time)
    enter_date_and_time("end", end_time)
  end

  def enter_date_and_time(prefix, time)
    fill_in "downtime[#{prefix}_time(3i)]", with: time.day.to_s
    fill_in "downtime[#{prefix}_time(2i)]", with: time.month.to_s
    fill_in "downtime[#{prefix}_time(1i)]", with: time.year.to_s
    fill_in "downtime[#{prefix}_time(4i)]", with: time.hour.to_s
    fill_in "downtime[#{prefix}_time(5i)]", with: time.min.to_s
  end
end
