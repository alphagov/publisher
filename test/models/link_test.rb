require_relative "../test_helper"

class LinkTest < ActiveSupport::TestCase
  setup do
    @link_check_report = FactoryBot.create(:link_check_report)
  end
  context "validations" do
    should "be valid when all fields set" do
      link = FactoryBot.build(:link, link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be valid without a checked time" do
      link = FactoryBot.build(:link, checked_at: nil, link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be valid without check warnings" do
      link = FactoryBot.build(:link, check_warnings: [], link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be valid without check errors" do
      link = FactoryBot.build(:link, check_errors: [], link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be valid without a problem summary" do
      link = FactoryBot.build(:link, problem_summary: nil, link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be valid without a suggested fix" do
      link = FactoryBot.build(:link, suggested_fix: nil, link_check_report: @link_check_report)
      assert link.valid?
    end

    should "be invalid without a uri" do
      link = FactoryBot.build(:link, uri: nil, link_check_report: @link_check_report)
      assert_not link.valid?
    end

    should "be invalid without a status" do
      link = FactoryBot.build(:link, status: nil, link_check_report: @link_check_report)
      assert_not link.valid?
    end

    should "store warnings as an array" do
      link = FactoryBot.build(:link, link_check_report: @link_check_report)
      assert_kind_of Array, link.check_warnings
    end

    should "store errors as an array" do
      link = FactoryBot.build(:link, link_check_report: @link_check_report)
      assert_kind_of Array, link.check_errors
    end
  end
end
