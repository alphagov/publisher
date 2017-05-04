require 'test_helper'

class WorkingDaysCalculatorTest < ActiveSupport::TestCase
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
end
