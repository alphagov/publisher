require 'test_helper'

class TimeZoneTest < ActiveSupport::TestCase
  def first_day_of_summer_time
    Time.zone.parse("2013-04-01")
  end

  def wintertime
    Time.zone.parse("2013-01-01")
  end

  context "use_activesupport_time_zone is set to true, Time.zone is set to 'London'" do
    setup do
      # This context has already been set in the local mongoid.yml, and in test_helper.rb
    end

    should "still store the date in UTC" do
      Timecop.freeze(wintertime) do
        FactoryGirl.create(:artefact)
        assert_equal 'UTC', Artefact.last[:created_at].zone
        assert_equal 'GMT', Artefact.last.created_at.zone
      end
    end

    should "use the Time.zone time zone for dot-methods" do
      Timecop.freeze(wintertime) do
        FactoryGirl.create(:artefact)
        assert_equal 'GMT', Artefact.last.created_at.zone
      end
    end

    context "it is currently British Summer Time" do
      should "still store the date in UTC" do
        Timecop.freeze(first_day_of_summer_time) do
          FactoryGirl.create(:artefact)
          assert_equal 'UTC', Artefact.last[:created_at].zone
        end
      end

      should "use the time zone with offset for dot-methods" do
        Timecop.freeze(first_day_of_summer_time) do
          FactoryGirl.create(:artefact)
          assert_equal 'BST', Artefact.last.created_at.zone
        end
      end
    end
  end
end
