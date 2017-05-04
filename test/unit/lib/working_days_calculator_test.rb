require 'test_helper'
require 'gds_api/test_helpers/calendars'

class WorkingDaysCalculatorTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::Calendars

  test "cares about england-and-wales holidays by default" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-27'))
    english_and_welsh_holidays = stub_request(:get, calendars_endpoint(in_division: 'england-and-wales')).to_return(status: 200, body: '{"events":[]}')
    scottish_holidays = stub_request(:get, calendars_endpoint(in_division: 'scotland')).to_return(status: 200, body: '{"events":[]}')
    northern_irish_holidays = stub_request(:get, calendars_endpoint(in_division: 'northern-ireland')).to_return(status: 200, body: '{"events":[]}')
    all_holidays = stub_request(:get, calendars_endpoint).to_return(status: 200, body: '{"events":[]}')

    calculator.public_holidays

    assert_requested(english_and_welsh_holidays)
    assert_not_requested(scottish_holidays)
    assert_not_requested(northern_irish_holidays)
    assert_not_requested(all_holidays)
  end

  test "cares about the division it is told to care about" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-27'), in_division: :scotland)
    english_and_welsh_holidays = stub_request(:get, calendars_endpoint(in_division: 'england-and-wales')).to_return(status: 200, body: '{"events":[]}')
    scottish_holidays = stub_request(:get, calendars_endpoint(in_division: 'scotland')).to_return(status: 200, body: '{"events":[]}')
    northern_irish_holidays = stub_request(:get, calendars_endpoint(in_division: 'northern-ireland')).to_return(status: 200, body: '{"events":[]}')
    all_holidays = stub_request(:get, calendars_endpoint).to_return(status: 200, body: '{"events":[]}')

    calculator.public_holidays

    assert_not_requested(english_and_welsh_holidays)
    assert_requested(scottish_holidays)
    assert_not_requested(northern_irish_holidays)
    assert_not_requested(all_holidays)
  end

  setup do
    calendars_has_no_bank_holidays(in_division: 'england-and-wales')
  end

  test ".after returns the correct weekday" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-27'))
    assert_equal Date.parse('2017-04-28'), calculator.after(1)
  end

  test ".after returns the Monday if the next day falls on a Saturday" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-21'))
    assert_equal Date.parse('2017-04-24'), calculator.after(1)
  end

  test ".after returns the Tuesday if the next day falls on a Sunday" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-21'))
    assert_equal Date.parse('2017-04-25'), calculator.after(2)
  end

  test ".after accounts for weekends crossed even if they're not the 'next day'" do
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-21'))
    assert_equal Date.parse('2017-04-26'), calculator.after(3)
  end

  test ".after returns the Tuesday if the next day is a holiday Monday" do
    calendars_has_a_bank_holiday_on(Date.parse('2017-05-01'), in_division: 'england-and-wales')
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-21'))
    assert_equal Date.parse('2017-05-2'), calculator.after(6)
  end

  test ".after returns the Monday if the next day is a holiday Friday" do
    calendars_has_a_bank_holiday_on(Date.parse('2016-01-01'), in_division: 'england-and-wales')
    calculator = WorkingDaysCalculator.new(Date.parse('2015-12-31'))
    assert_equal Date.parse('2016-01-4'), calculator.after(1)
  end

  test ".after returns the Tuesday if the next day is a holiday on both Friday and Monday" do
    calendars_has_bank_holidays_on([Date.parse('2017-04-14'), Date.parse('2017-04-17')], in_division: 'england-and-wales')
    calculator = WorkingDaysCalculator.new(Date.parse('2017-04-13'))
    assert_equal Date.parse('2017-04-18'), calculator.after(1)
  end

  test ".after accounts for holidays crossed even if they're not the 'next day'" do
    calendars_has_a_bank_holiday_on(Date.parse('2014-01-01'), in_division: 'england-and-wales')
    calculator = WorkingDaysCalculator.new(Date.parse('2013-12-31'))
    assert_equal Date.parse('2014-01-03'), calculator.after(2)
  end
end
