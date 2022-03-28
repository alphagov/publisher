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
  end

  test "Scheduling new downtime with invalid dates" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)

    visit root_path
    click_link "Downtime"
    click_link "Apply to become a driving instructor"

    enter_start_time 1.day.ago
    enter_end_time 1.day.ago - 1.day

    click_button "Schedule downtime message"

    assert page.has_link?("End time must be in the future", href: "#downtime_end_time")
    assert page.has_link?("Start time must be earlier than end time", href: "#downtime_start_time")
  end

  def enter_start_time(start_time)
    complete_date_inputs("downtime_start_time", start_time)
  end

  def enter_end_time(end_time)
    complete_date_inputs("downtime_end_time", end_time)
  end

  def complete_date_inputs(input_id, time)
    select time.year.to_s, from: "#{input_id}_1i"
    select time.strftime("%B"), from: "#{input_id}_2i"
    select time.day.to_s, from: "#{input_id}_3i"
    select pad_digit_to_two_digits(time.hour.to_s), from: "#{input_id}_4i"
    select time.strftime("%M"), from: "#{input_id}_5i"
  end

  def pad_digit_to_two_digits(hour_string)
    hour_string.length == 1 ? "0#{hour_string}" : hour_string
  end
end
