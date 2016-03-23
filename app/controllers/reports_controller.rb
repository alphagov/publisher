class ReportsController < ApplicationController
  include ActionView::Helpers::TagHelper

  before_filter :authenticate_user!

  def index
  end

  def progress
    send_report "editorial_progress"
  end

  def business_support_schemes_content
    send_report "business_support_export"
  end

  def organisation_content
    send_report "organisation_content"
  end

  def edition_churn
    send_report "edition_churn"
  end

  def content_workflow
    send_report "content_workflow"
  end

  private

  def report_last_updated(report)
    if mtime = mtime_for(report)
      content_tag :span, "Generated #{mtime.to_s(:govuk_date)}", class: "text-muted"
    else
      content_tag :span, "Report currently unavailable", class: "text-muted"
    end
  end
  helper_method :report_last_updated

  def mtime_for(report)
    mtime = File.stat(report_location(report)).mtime.in_time_zone(Time.zone)
  rescue Errno::ENOENT
    nil
  end

  def report_location(report)
    File.join(CsvReportGenerator.csv_path, "#{report}.csv")
  end

  def send_report(report)
    if File.exist?(report_location(report))
      send_file report_location(report),
        filename: "#{report}-#{mtime_for(report).strftime("%Y%m%d%H%M%S")}.csv",
        type: "text/csv",
        disposition: "attachment"
    else
      render nothing: true, status: 404
    end
  end
end
