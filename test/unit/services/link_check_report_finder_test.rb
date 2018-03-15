require "test_helper"

class LinkCheckReportFinderTest < ActiveSupport::TestCase
  def link_check_report
    @link_check_report ||= FactoryBot.create(:edition, :with_link_check_report,
      link_uris: ['https://www.gov.uk']).latest_link_check_report
  end

  context ".call" do
    should "find the link check report" do
      result = LinkCheckReportFinder.new(report_id: link_check_report.id).call

      assert result
      assert_same_elements ['https://www.gov.uk'], result.links.map(&:uri)
    end
  end
end
