require 'test_helper'

class BusinessSupportLocationMigratorTest < ActiveSupport::TestCase

  def setup
    @bs1 = FactoryGirl.create(:business_support_edition, :locations => ["london", "south-east"])
    @bs2 = FactoryGirl.create(:business_support_edition, :locations => ["england", "wales"])
    @bs3 = FactoryGirl.create(:business_support_edition, :locations => [])

    silence_stream(STDOUT) do
      BusinessSupportLocationMigrator.run
    end

    [@bs1, @bs2, @bs3].map(&:reload)
  end

  def test_run
    assert_equal ['9728','9733'], @bs1.areas
    assert_equal ['9728','9729','9734','9727','9731','9732','9736','9733','9726','9735'], @bs2.areas
    assert_equal [], @bs3.areas
  end
end
