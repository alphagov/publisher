require 'working_days_calculator'

module WorkingDaysHelper
  def working_days_after(date, how_many:)
    WorkingDaysCalculator.new(date).after(how_many)
  end
end
