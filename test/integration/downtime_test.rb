require 'integration_test_helper'

class DowntimeTest < JavascriptIntegrationTest
  test "scheduling and removing downtime" do
    setup_users

    transaction = FactoryGirl.create(:transaction_edition, :published,
      title: 'Apply to become a driving instructor', slug: 'apply-to-become-a-driving-instructor')

    visit root_path
    click_link 'Downtime'
    click_link 'Apply to become a driving instructor'

    tomorrow = Date.tomorrow
    select tomorrow.year.to_s, from: 'downtime_start_time_1i'
    select tomorrow.strftime('%B'), from: 'downtime_start_time_2i'
    select tomorrow.day.to_s, from: 'downtime_start_time_3i'
    select '12', from: 'downtime_start_time_4i'
    select '00', from: 'downtime_start_time_5i'

    select tomorrow.year.to_s, from: 'downtime_end_time_1i'
    select tomorrow.strftime('%B'), from: 'downtime_end_time_2i'
    select tomorrow.day.to_s, from: 'downtime_end_time_3i'
    select '18', from: 'downtime_end_time_4i'
    select '00', from: 'downtime_end_time_5i'
    assert_match("midday to 6pm on #{tomorrow.strftime('%A')} #{tomorrow.day} #{tomorrow.strftime('%b')}", page.find_field('Message').value)
    click_on 'Schedule downtime'

    assert page.has_content?('Successfully scheduled downtime')

    visit downtimes_path
    assert page.has_content?('Scheduled downtime')
    assert page.has_content?("midday to 6pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")

    click_link 'Edit downtime'
    select '21', from: 'downtime_end_time_4i'
    select '30', from: 'downtime_end_time_5i'
    assert_match("midday to 9:30pm on #{tomorrow.strftime('%A')} #{tomorrow.day} #{tomorrow.strftime('%b')}", page.find_field('Message').value)
    click_on 'Re-schedule downtime message'
    assert page.has_content?('Successfully updated downtime')

    visit downtimes_path
    assert page.has_content?("midday to 9:30pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")

    click_link 'Edit downtime'
    click_on 'Cancel downtime'
    assert page.has_content?('Successfully cancelled downtime')

    visit downtimes_path
    refute page.has_content?("midday to 9:30pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")
  end
end
