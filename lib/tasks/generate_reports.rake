require 'csv_report_generator'

namespace :reports do
  desc "Generate long-running CSV reports for use by users."
  task generate: [:environment] do
    CsvReportGenerator.new.run!
  end
end
