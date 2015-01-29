require "test_helper"

class ExpiredDowntimeCleanerTest < ActiveSupport::TestCase
  context ".perform" do
    should "delete downtime" do
      downtime = Downtime.new(FactoryGirl.attributes_for(:downtime, start_time: 2.days.ago, end_time: 1.day.ago))
      downtime.save(validate: false)

      ExpiredDowntimeCleaner.new.perform(downtime.id.to_s)
      assert_raises(Mongoid::Errors::DocumentNotFound) { downtime.reload }
    end

    should "not delete downtime if end_time is in future" do
      downtime = FactoryGirl.create(:downtime, end_time: 2.days.from_now)

      ExpiredDowntimeCleaner.new.perform(downtime.id.to_s)
      assert downtime.reload
    end
  end
end
