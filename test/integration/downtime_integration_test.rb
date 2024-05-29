require "integration_test_helper"

class DowntimeIntegrationTest < JavascriptIntegrationTest
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
    test_strategy.switch!(:design_system_downtime_edit, true)
  end

  test "Scheduling new downtime" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)

    visit root_path
    click_link "Downtime"
    click_link "Add downtime"

    enter_from_date_and_time first_of_july_next_year_at_midday_bst
    enter_to_date_and_time first_of_july_next_year_at_six_pm_bst

    assert_match("midday to 6pm on #{day} 1 July", page.find_field("Message").value)
    click_button "Save"

    assert_text "downtime message scheduled"
    assert_text "Scheduled downtime midday to 6pm on 1 July"
  end

  test "Rescheduling downtime" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)
    create_downtime

    visit root_path
    click_link "Downtime"
    click_link "Edit downtime"
    enter_to_date_and_time first_of_july_next_year_at_nine_thirty_pm_bst

    find("textarea#downtime_message").click

    assert_match("This service will be unavailable from midday to 9:30pm on #{day} 1 July.", page.find_field("Message").value)
    click_on "Save"

    assert page.has_content?("downtime message re-scheduled")
    assert page.has_content?("midday to 9:30pm on 1 July")
  end

  test "Cancelling downtime" do
    PublishingApiWorkflowBypassPublisher.stubs(:call)
    create_downtime

    visit root_path
    click_link "Downtime"
    click_link "Edit downtime"
    click_link "Remove"
    click_on "Remove"

    assert page.has_content?("downtime message cancelled")
    assert_no_downtime_scheduled
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

  def legacy_enter_start_time(start_time)
    complete_date_inputs("downtime_start_time", start_time)
  end

  def legacy_enter_end_time(end_time)
    complete_date_inputs("downtime_end_time", end_time)
  end

  def complete_date_inputs(input_id, time)
    select time.year.to_s, from: "#{input_id}_1i"
    select time.strftime("%B"), from: "#{input_id}_2i"
    select time.day.to_s, from: "#{input_id}_3i"
    select time.hour.to_s, from: "#{input_id}_4i"
    select time.strftime("%M"), from: "#{input_id}_5i"
  end

  def next_year
    Time.zone.now.next_year.year
  end

  def date_in_the_past
    Time.zone.local(Time.zone.now.last_year.year, 1, 1, 12, 0)
  end

  def first_of_july_next_year_at_midday_bst
    Time.zone.local(next_year, 7, 1, 12, 0)
  end

  def first_of_july_next_year_at_six_pm_bst
    Time.zone.local(next_year, 7, 1, 18, 0)
  end

  def first_of_july_next_year_at_nine_thirty_pm_bst
    Time.zone.local(next_year, 7, 1, 21, 30)
  end

  def day
    first_of_july_next_year_at_six_pm_bst.strftime("%A")
  end

  def create_downtime
    Downtime.create!(
      artefact: @edition.artefact,
      start_time: first_of_july_next_year_at_midday_bst,
      end_time: first_of_july_next_year_at_six_pm_bst,
      message: "foo",
    )
  end

  def assert_no_downtime_scheduled
    assert_equal 0, Downtime.count
  end
end
