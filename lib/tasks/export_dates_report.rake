desc "Export Published Mainstream Content title and URL between 2 dates, as CSV"

task :export_dates_report, [:start_date, :end_date] => :environment do |_, args|
  USAGE_MESSAGE = "usage: rake export_dates_report[<start_date>, <end_date>]\n"\
    "dates format: YYYY-MM-DD"
  abort USAGE_MESSAGE unless args[:start_date] && args[:end_date]
  begin
    start_date = Date.parse(args[:start_date])
    end_date = Date.parse(args[:end_date])
  rescue ArgumentError
    abort USAGE_MESSAGE
  end

  path = CsvReportGenerator.csv_path
  DatesReportPresenter.new(start_date, end_date).write_csv(path)

  puts "Report successfully generated inside #{path} !"
end
