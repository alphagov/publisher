require "test_helper"

class DowntimesHelperTest < ActionView::TestCase
  include DowntimesHelper

  def setup
    @next_year = 1.year.from_now.year
  end

  test "#downtime_datetime should be a short string representation start and end time" do
    downtime = FactoryGirl.build(:downtime, start_time: Time.zone.local(@next_year, 10, 10, 15), end_time: Time.zone.local(@next_year, 10, 11, 18))
    assert_equal "3pm on 10 October to 6pm on 11 October", downtime_datetime(downtime)
  end

  test "#downtime_datetime should not repeat date if start and end times are on the same day" do
    downtime = FactoryGirl.build(:downtime, start_time: Time.zone.local(@next_year, 10, 11, 15), end_time: Time.zone.local(@next_year, 10, 11, 18))
    assert_equal "3pm to 6pm on 11 October", downtime_datetime(downtime)
  end

  test "#downtime_datetime should not repeat date if downtime ends at midnight on next day" do
    downtime = FactoryGirl.build(:downtime, start_time: Time.zone.local(@next_year, 10, 10, 21), end_time: Time.zone.local(@next_year, 10, 11, 0))
    assert_equal "9pm to midnight on 10 October", downtime_datetime(downtime)
  end
end
