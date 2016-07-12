require 'integration_test_helper'

class DowntimeTest < JavascriptIntegrationTest
  teardown do
    Sidekiq::ScheduledSet.new.clear
  end

  test "scheduling and removing downtime" do
    Sidekiq::Testing.disable! do
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

      assert_equal 1, Sidekiq::ScheduledSet.new.size
      assert_equal [Downtime.last.id.to_s, { "authenticated_user" => nil, "request_id" => nil }], Sidekiq::ScheduledSet.new.first.args

      assert page.has_content?('Apply to become a driving instructor downtime message scheduled')
      assert page.has_content?('Scheduled downtime')
      assert page.has_content?("midday to 6pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")

      click_link 'Edit downtime'
      select '21', from: 'downtime_end_time_4i'
      select '30', from: 'downtime_end_time_5i'
      assert_match("midday to 9:30pm on #{tomorrow.strftime('%A')} #{tomorrow.day} #{tomorrow.strftime('%b')}", page.find_field('Message').value)
      click_on 'Re-schedule downtime message'

      assert_equal 1, Sidekiq::ScheduledSet.new.size
      assert_equal [Downtime.last.id.to_s, { "authenticated_user" => nil, "request_id" => nil }], Sidekiq::ScheduledSet.new.first.args

      assert page.has_content?('Apply to become a driving instructor downtime message re-scheduled')
      assert page.has_content?("midday to 9:30pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")

      click_link 'Edit downtime'
      click_on 'Cancel downtime'

      assert_equal 0, Sidekiq::ScheduledSet.new.size

      assert page.has_content?('Apply to become a driving instructor downtime message cancelled')
      refute page.has_content?("midday to 9:30pm on #{tomorrow.day} #{tomorrow.strftime('%b')}")
    end
  end
end
