require "integration_test_helper"

class DowntimeWithInvalidDates < IntegrationTest
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
    click_link "Add downtime"

    start_time = 1.day.ago
    end_time = start_time - 1.day
    enter_from_date_and_time start_time
    enter_to_date_and_time end_time

    click_button "Save"

    assert page.has_link?("End time must be in the future", href: "#downtime_end_time")
    assert page.has_link?("Start time must be earlier than end time", href: "#downtime_start_time")
    assert page.has_field?("downtime[start_time(1i)]", with: start_time.year.to_s)
    assert page.has_field?("downtime[start_time(2i)]", with: start_time.month.to_s)
    assert page.has_field?("downtime[start_time(3i)]", with: start_time.day.to_s)
    assert page.has_field?("downtime[start_time(4i)]", with: start_time.hour.to_s)
    assert page.has_field?("downtime[start_time(5i)]", with: start_time.min.to_s)
    assert page.has_field?("downtime[end_time(1i)]", with: end_time.year.to_s)
    assert page.has_field?("downtime[end_time(2i)]", with: end_time.month.to_s)
    assert page.has_field?("downtime[end_time(3i)]", with: end_time.day.to_s)
    assert page.has_field?("downtime[end_time(4i)]", with: end_time.hour.to_s)
    assert page.has_field?("downtime[end_time(5i)]", with: end_time.min.to_s)
  end

  test "Rescheduling new downtime with invalid dates" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)
    create_downtime

    visit root_path
    click_link "Downtime"
    click_link "Edit downtime"

    start_time = 1.day.ago
    end_time = start_time - 1.day
    enter_from_date_and_time start_time
    enter_to_date_and_time end_time

    find("textarea#downtime_message").click

    click_button "Save"

    assert page.has_link?("End time must be in the future", href: "#downtime_end_time")
    assert page.has_link?("Start time must be earlier than end time", href: "#downtime_start_time")
    assert page.has_field?("downtime[start_time(1i)]", with: start_time.year.to_s)
    assert page.has_field?("downtime[start_time(2i)]", with: start_time.month.to_s)
    assert page.has_field?("downtime[start_time(3i)]", with: start_time.day.to_s)
    assert page.has_field?("downtime[start_time(4i)]", with: start_time.hour.to_s)
    assert page.has_field?("downtime[start_time(5i)]", with: start_time.min.to_s)
    assert page.has_field?("downtime[end_time(1i)]", with: end_time.year.to_s)
    assert page.has_field?("downtime[end_time(2i)]", with: end_time.month.to_s)
    assert page.has_field?("downtime[end_time(3i)]", with: end_time.day.to_s)
    assert page.has_field?("downtime[end_time(4i)]", with: end_time.hour.to_s)
    assert page.has_field?("downtime[end_time(5i)]", with: end_time.min.to_s)
  end

  test "Rescheduling downtime with missing day field" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)
    create_downtime

    visit root_path
    click_link "Downtime"
    click_link "Edit downtime"

    fill_in "downtime[end_time(3i)]", with: ""

    find("textarea#downtime_message").click

    click_on "Save"

    assert page.has_content?("End time format is invalid")
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

  def create_downtime
    Downtime.create!(
      artefact_id: @edition.artefact.id,
      start_time: first_of_july_next_year_at_midday_bst,
      end_time: first_of_july_next_year_at_six_pm_bst,
      message: "foo",
    )
  end

  def first_of_july_next_year_at_midday_bst
    Time.zone.local(next_year, 7, 1, 12, 0)
  end

  def first_of_july_next_year_at_six_pm_bst
    Time.zone.local(next_year, 7, 1, 18, 0)
  end

  def next_year
    Time.zone.now.next_year.year
  end
end
