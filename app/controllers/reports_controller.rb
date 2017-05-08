class ReportsController < ApplicationController
  include ActionView::Helpers::TagHelper

  before_action :authenticate_user!

  def index
  end

  def progress
    send_report "editorial_progress"
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
    mtime = mtime_for(report)
    if mtime
      content_tag :span, "Generated #{mtime.to_s(:govuk_date)}", class: "text-muted"
    else
      content_tag :span, "Report currently unavailable", class: "text-muted"
    end
  end
  helper_method :report_last_updated

  def mtime_for(report)
    File.stat(report_location(report)).mtime.in_time_zone(Time.zone)
  rescue Errno::ENOENT
    nil
  end

  def report_location(report)
    File.join(CsvReportGenerator.csv_path, "#{report}.csv")
  end

  def send_report(report)
    if File.exist?(report_location(report))
      send_file report_location(report),
        filename: "#{report}-#{mtime_for(report).strftime('%Y%m%d%H%M%S')}.csv",
        type: "text/csv",
        disposition: "attachment"
    else
      return head(:not_found)
    end
  end
end
