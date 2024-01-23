require "test_helper"

class FeatureConstraintTest < ActiveSupport::TestCase
	context "FeatureConstraint" do
		setup	do
			@feature_to_test = FeatureConstraint.new("example")
		end

		should "return true if Feature example enabled" do
			Flipper.enable :example
			assert_equal true, @feature_to_test.matches?({})
		end
		
		should "return false if Feature example disabled" do
			Flipper.disable :example
			assert_equal false, @feature_to_test.matches?({})
		end		
	end
end

