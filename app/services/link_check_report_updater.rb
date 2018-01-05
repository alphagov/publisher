class LinkCheckReportUpdater
  def initialize(report:, payload:)
    @report = report
    @payload = payload
  end

  def call
    update_report!
    links = payload.fetch("links", [])
    update_links!(links)
  end

private

  attr_reader :report, :payload

  def update_report!
    report.update!(
      status: payload.fetch("status"),
      completed_at: payload.fetch("completed_at"),
    )
  end

  def update_links!(links_payload)
    links_payload.each do |link_payload|
      link = report.links.find_by(uri: link_payload.fetch("uri"))

      attributes = link_attributes(link_payload)

      link.update!(attributes)
    end
  end

  def link_attributes(link)
    {
      uri: link.fetch(:uri),
      status: link.fetch(:status),
      checked_at: link.fetch(:checked),
      check_warnings: link.fetch(:warnings, []),
      check_errors: link.fetch(:errors, []),
      problem_summary: link.fetch(:problem_summary),
      suggested_fix: link.fetch(:suggested_fix)
    }
  end
end
