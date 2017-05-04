class WorkingDaysCalculator
  def initialize(starting_from)
    @starting_from = starting_from
  end

  def after(how_many_days, skip_days: 0)
    days = (@starting_from.tomorrow..(@starting_from + how_many_days + skip_days))
    calculated_skip_days = days.select { |day| holiday?(day) }.count
    return days.last if calculated_skip_days == skip_days
    after(how_many_days, skip_days: calculated_skip_days)
  end

  def holiday?(date)
    date.saturday? || date.sunday?
  end
end
