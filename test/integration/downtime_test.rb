require 'integration_test_helper'

class DowntimeTest < JavascriptIntegrationTest
  setup do
    setup_users

    @edition = FactoryGirl.create(
      :transaction_edition,
      :published,
      title: 'Apply to become a driving instructor',
      slug: 'apply-to-become-a-driving-instructor'
    )

    WebMock.reset!
    stub_any_publishing_api_put_content
    stub_any_publishing_api_publish
  end

  test "Scheduling new downtime" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)

    visit root_path
    click_link 'Downtime'
    click_link 'Apply to become a driving instructor'

    enter_start_time first_of_july_next_year_at_midday_bst
    enter_end_time first_of_july_next_year_at_six_pm_bst

    assert_match("midday to 6pm on #{day} 1 July", page.find_field('Message').value)
    click_button 'Schedule downtime message'

    assert page.has_content?('Apply to become a driving instructor downtime message scheduled')
    assert page.has_content?('Scheduled downtime')
    assert page.has_content?("midday to 6pm on 1 July")
  end

  test "Rescheduling downtime" do
    DowntimeScheduler.stubs(:schedule_publish_and_expiry)
    create_downtime

    visit root_path
    click_link 'Downtime'
    click_link 'Edit downtime'
    enter_end_time first_of_july_next_year_at_nine_thirty_pm_bst

    assert_match("This service will be unavailable from midday to 9:30pm on #{day} 1 July.", page.find_field('Message').value)
    click_on 'Re-schedule downtime message'

    assert page.has_content?('Apply to become a driving instructor downtime message re-scheduled')
    assert page.has_content?("midday to 9:30pm on 1 July")
  end

  test "Cancelling downtime" do
    PublishingApiWorkflowBypassPublisher.stubs(:call)
    create_downtime

    visit root_path
    click_link 'Downtime'
    click_link 'Edit downtime'
    click_on 'Cancel downtime'

    assert page.has_content?('Apply to become a driving instructor downtime message cancelled')
    assert_no_downtime_scheduled
  end

  def enter_start_time(start_time)
    complete_date_inputs('downtime_start_time', start_time)
  end

  def enter_end_time(end_time)
    complete_date_inputs('downtime_end_time', end_time)
  end

  def complete_date_inputs(input_id, time)
    select time.year.to_s, from: "#{input_id}_1i"
    select time.strftime('%B'), from: "#{input_id}_2i"
    select time.day.to_s, from: "#{input_id}_3i"
    select time.hour.to_s, from: "#{input_id}_4i"
    select time.strftime('%M'), from: "#{input_id}_5i"
  end

  def next_year
    Time.zone.now.next_year.year
  end

  def first_of_july_next_year_at_midday_bst
    Time.new(next_year, 7, 1, 11, 0).in_time_zone
  end

  def first_of_july_next_year_at_six_pm_bst
    Time.new(next_year, 7, 1, 17, 0).in_time_zone
  end

  def first_of_july_next_year_at_nine_thirty_pm_bst
    Time.new(next_year, 7, 1, 20, 30).in_time_zone
  end

  def day
    first_of_july_next_year_at_six_pm_bst.strftime('%A')
  end

  def create_downtime
    Downtime.create!(
      artefact: @edition.artefact,
      start_time: first_of_july_next_year_at_midday_bst,
      end_time: first_of_july_next_year_at_six_pm_bst,
      message: 'foo'
    )
  end

  def assert_no_downtime_scheduled
    assert_equal 0, Downtime.count
  end
end
