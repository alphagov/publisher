require_relative '../test_helper'

class LinkCheckReportTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid when all fields set" do
      link_check_report = FactoryGirl.build(:link_check_report, :completed)
      assert link_check_report.valid?
    end

    should "be valid without a completed at time" do
      link_check_report = FactoryGirl.build(:link_check_report, completed_at: nil)
      assert link_check_report.valid?
    end

    should "be invalid without links" do
      link_check_report = FactoryGirl.build(:link_check_report, links: [])
      refute link_check_report.valid?
    end

    should "be invalid without a batch id" do
      link_check_report = FactoryGirl.build(:link_check_report, batch_id: nil)
      refute link_check_report.valid?
    end

    should "be invalid without a status" do
      link_check_report = FactoryGirl.build(:link_check_report, status: nil)
      refute link_check_report.valid?
    end
  end

  context "#completed?" do
    should "return true when complete" do
      link_check_report = FactoryGirl.build(:link_check_report, :completed)
      assert link_check_report.completed?
    end

    should "return false when not complete" do
      link_check_report = FactoryGirl.build(:link_check_report)
      refute link_check_report.completed?
    end
  end

  context "#in_progress?" do
    should "retun true when in progress" do
      link_check_report = FactoryGirl.build(:link_check_report)
      assert link_check_report.in_progress?
    end
  end

  context "#broken_links" do
    should "return an array of broken links" do
      link_check_report = FactoryGirl.build(:link_check_report, :with_links,
                                                                link_uris: ["https://www.gov.uk"],
                                                                link_status: "broken")
      assert_kind_of Array, link_check_report.broken_links
      assert link_check_report.broken_links.any?
      assert "https://www.gov.uk", link_check_report.broken_links.first.uri
    end
  end

  context "#caution_links" do
    should "return an array of caution links" do
      link_check_report = FactoryGirl.build(:link_check_report, :with_links,
                                                                link_uris: ["https://www.gov.uk"],
                                                                link_status: "caution")
      assert_kind_of Array, link_check_report.caution_links
      assert link_check_report.caution_links.any?
      assert "https://www.gov.uk", link_check_report.caution_links.first.uri
    end
  end
end
