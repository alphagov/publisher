class LinkCheckReportFinder
  def initialize(report_id:)
    @report_id = report_id
  end

  def call
    link_check_report
  end

private

  attr_reader :report_id

  def link_check_report
    @link_check_report ||= LinkCheckReport.find(report_id)
  end
end
