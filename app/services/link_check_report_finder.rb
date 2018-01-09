class LinkCheckReportFinder
  def initialize(report_id:)
    @report_id = report_id
  end

  def call
    link_check_report
  end

private

  attr_reader :report_id

  def edition
    @edition ||= Edition.find_by("link_check_reports._id": report_id)
  end

  def link_check_report
    @link_check_report ||= edition.link_check_reports.find_by(id: report_id)
  end
end
