require "test_helper"

class LinkCheckReportUpdaterTest < ActiveSupport::TestCase
  def completed_at
    @completed_at ||= Time.now.utc
  end

  def payload
    {
      status: 'complete',
      completed_at: completed_at,
      links: links_payload
    }.with_indifferent_access
  end

  def links_payload
    [{
      uri: "http://www.example.com",
      status: "ok",
      checked: completed_at.try(:iso8601),
      problem_summary: nil,
      suggested_fix: nil
    }, {
      uri: "http://www.gov.com",
      status: "broken",
      checked: completed_at.try(:iso8601),
      problem_summary: "Page Not Found",
      suggested_fix: "Contact site administrator"
    }]
  end

  def create_edition_with_link_check_report
    FactoryBot.create(:edition, :with_link_check_report,
                                 batch_id: 1,
                                 link_uris: ['http://www.example.com', 'http://www.gov.com'])
  end

  def link_check_report
    @link_check_report ||= create_edition_with_link_check_report.link_check_reports.first
  end

  should 'update the link check report' do
    LinkCheckReportUpdater.new(report: link_check_report, payload: payload).call

    link_check_report.reload

    assert "complete", link_check_report.status
    assert completed_at, link_check_report.completed_at
  end

  should 'update the links status' do
    LinkCheckReportUpdater.new(report: link_check_report, payload: payload).call

    link_check_report.reload

    assert "ok", link_check_report.links.first.status
    assert completed_at.try(:iso8601), link_check_report.links.first.checked_at

    assert "broken", link_check_report.links.last.status
    assert completed_at.try(:iso8601), link_check_report.links.last.checked_at
    assert "Page Not Found", link_check_report.links.last.problem_summary
  end
end
