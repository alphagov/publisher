require 'gds_api/calendars'

class WorkingDaysCalculator
  def initialize(starting_from, in_division: :england_and_wales)
    @starting_from = starting_from
    @calendar_division = in_division
  end

  def after(how_many_days, skip_days: 0)
    days = (@starting_from.tomorrow..(@starting_from + how_many_days + skip_days))
    calculated_skip_days = days.count { |day| holiday?(day) }
    return days.last if calculated_skip_days == skip_days
    after(how_many_days, skip_days: calculated_skip_days)
  end

  def holiday?(date)
    date.saturday? || date.sunday? || public_holidays.include?(date)
  end

  def public_holidays
    @public_holidays ||= fetch_public_holidays
  end

private

  def fetch_public_holidays
    public_holidays_json = Services.calendars.bank_holidays(@calendar_division)
    public_holidays_json['events'].map { |event| Date.parse(event["date"]) }
  end
end
