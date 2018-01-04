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
end
