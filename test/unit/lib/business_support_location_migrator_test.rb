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
    assert_equal ['london','south-east'], @bs1.areas
    assert_equal ['london','north-west','north-east','east-midlands','west-midlands','yorkshire-and-the-humber','south-west','south-east','eastern','wales'], @bs2.areas
    assert_equal [], @bs3.areas
  end
end
