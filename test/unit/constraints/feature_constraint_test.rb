require "test_helper"

class FeatureConstraintTest < ActiveSupport::TestCase
  context "Feature 'feature_for_tests' is enabled by default" do
    setup do
      @test_strategy.switch!(:feature_for_tests, true)
    end

    should "match when a request cookie explicitly enables feature" do
      request = stub(cookies: { "feature_for_tests" => "1" })

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal true, feature_constraint.matches?(request)
    end

    should "not match when a request cookie explicitly disables feature" do
      request = stub(cookies: { "feature_for_tests" => "0" })

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal false, feature_constraint.matches?(request)
    end

    should "match when a request cookie does not override default feature status" do
      request = stub(cookies: {})

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal true, feature_constraint.matches?(request)
    end
  end

  context "Feature 'feature_for_tests' is disabled by default" do
    setup do
      @test_strategy.switch!(:feature_for_tests, false)
    end

    should "match when a request cookie explicitly enables feature" do
      request = stub(cookies: { "feature_for_tests" => "1" })

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal true, feature_constraint.matches?(request)
    end

    should "not match when a request cookie explicitly disables feature" do
      request = stub(cookies: { "feature_for_tests" => "0" })

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal false, feature_constraint.matches?(request)
    end

    should "not match when a request cookie does not override default feature status" do
      request = stub(cookies: {})

      feature_constraint = FeatureConstraint.new("feature_for_tests")

      assert_equal false, feature_constraint.matches?(request)
    end
  end
end
