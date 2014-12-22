require 'integration_test_helper'

class ChangeEditionTypeTest < ActionDispatch::IntegrationTest
  test "doesn't show change note until an edition has been published" do
    pending 'WIP'

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
    click_on 'Schedule downtime'

    visit downtimes_path
    assert page.has_content?('Scheduled downtime')
    assert page.has_content?("12:00 #{tomorrow.day} #{tomorrow.strftime('%b')} to 18:00 #{tomorrow.day} #{tomorrow.strftime('%b')}")
  end
end
