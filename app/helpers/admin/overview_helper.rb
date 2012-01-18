module Admin::OverviewHelper
  def format_group_name(group_name)
    names = {OverviewDashboard::TOTAL_KEY => 'Total', OverviewDashboard::UNASSIGNED_KEY => 'Unassigned'}
    names[group_name].nil? ? group_name : names[group_name]
  end

  def is_total_row?(row)
    (!row.nil?) && OverviewDashboard::TOTAL_KEY == row[:result_group]
  end

  def get_total_row(rows)
    rows.select { |row| is_total_row?(row) }.first
  end
end