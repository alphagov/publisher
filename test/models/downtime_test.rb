require "test_helper"

class DowntimeTest < ActiveSupport::TestCase
  context "validations" do
    should "validate presence of message" do
      downtime = FactoryGirl.build(:downtime, message: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:message], "can't be blank"
    end

    should "validate presence of start time" do
      downtime = FactoryGirl.build(:downtime, start_time: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:start_time], "can't be blank"
    end

    should "validate presence of end time" do
      downtime = FactoryGirl.build(:downtime, end_time: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:end_time], "can't be blank"
    end

    should "validate presence of artefact" do
      downtime = FactoryGirl.build(:downtime, artefact: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:artefact], "can't be blank"
    end

    should "validate end time is in future" do
      downtime = FactoryGirl.build(:downtime, end_time: Date.today - 1)

      refute downtime.valid?
      assert_includes downtime.errors[:end_time], 'must be in the future'
    end

    should "validate end time is in future only on create" do
      downtime = FactoryGirl.create(:downtime)
      downtime.assign_attributes(start_time: Date.today - 3, end_time: Date.today - 1)

      assert downtime.valid?
    end

    should "validate start time is earlier than end time" do
      downtime = FactoryGirl.build(:downtime, start_time: Date.today + 2, end_time: Date.today + 1)

      refute downtime.valid?
      assert_includes downtime.errors[:start_time], "must be earlier than end time"
    end
  end

  context "for an artefact" do
    should "be returned if found" do
      downtime = FactoryGirl.create(:downtime)
      assert_equal downtime, Downtime.for(downtime.artefact)
    end

    should "be nil if not found" do
      assert_nil Downtime.for(FactoryGirl.build(:artefact))
    end
  end

  context "publicising downtime" do
    should "start at display_start_time" do
      now = Time.zone.parse("2015-01-01")
      Timecop.freeze(now) do
        downtime = FactoryGirl.build(:downtime)

        downtime.start_time = Time.zone.parse("2015-01-02 03:00")
        assert downtime.publicise?

        downtime.start_time = Time.zone.parse("2015-01-01 21:00")
        assert downtime.publicise?

        downtime.start_time = Time.zone.parse("2015-01-03 00:00")
        refute downtime.publicise?
      end
    end

    should "stop after scheduled end time" do
      Timecop.freeze(Time.zone.now + 10) do
        downtime = FactoryGirl.build(:downtime)

        downtime.end_time = Time.zone.now - 1.minute
        refute downtime.publicise?
      end
    end
  end

  context "#display_start_time" do
    should "return the datetime of midnight the day before it's scheduled" do
      downtime = FactoryGirl.build(:downtime)
      downtime.start_time = Time.zone.parse("2015-01-02 03:00")
      expected_start_time = Time.zone.parse("2015-01-01 00:00")
      assert_equal expected_start_time, downtime.display_start_time
    end
  end
end
