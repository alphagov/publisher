class LinkCheckReportFinder
  def initialize(report_id:)
    @report_id = report_id
  end

  def call
    link_check_report
  end

private

  attr_reader :report_id

  #come back to this - need to go in depth of link check report changes
  def edition
    @edition ||= LinkCheckReport.find(report_id).edition
  end

  def link_check_report
    @link_check_report ||= edition.link_check_reports.find_by(id: report_id)
  end
end
