require_relative '../test_helper'

class LinkTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid when all fields set" do
      link = FactoryGirl.build(:link)
      assert link.valid?
    end

    should "be valid without a checked time" do
      link = FactoryGirl.build(:link, checked_at: nil)
      assert link.valid?
    end

    should "be valid without check warnings" do
      link = FactoryGirl.build(:link, check_warnings: [])
      assert link.valid?
    end

    should "be valid without check errors" do
      link = FactoryGirl.build(:link, check_errors: [])
      assert link.valid?
    end

    should "be valid without a problem summary" do
      link = FactoryGirl.build(:link, problem_summary: nil)
      assert link.valid?
    end

    should "be valid without a suggested fix" do
      link = FactoryGirl.build(:link, suggested_fix: nil)
      assert link.valid?
    end

    should "be invalid without a uri" do
      link = FactoryGirl.build(:link, uri: nil)
      refute link.valid?
    end

    should "be invalid without a status" do
      link = FactoryGirl.build(:link, status: nil)
      refute link.valid?
    end

    should "store warnings as an array" do
      link = FactoryGirl.build(:link)
      assert_kind_of Array, link.check_warnings
    end

    should "store errors as an array" do
      link = FactoryGirl.build(:link)
      assert_kind_of Array, link.check_errors
    end
  end
end
