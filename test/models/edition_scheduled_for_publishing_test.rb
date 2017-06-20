require "test_helper"

class EditionScheduledForPublishingTest < ActiveSupport::TestCase
  context "#schedule_for_publishing" do
    context "when publish_at is not specified" do
      setup do
        @edition = FactoryGirl.create(:edition, state: 'ready')
        @edition.schedule_for_publishing
      end

      should "return an error" do
        assert_includes @edition.errors[:publish_at], "can't be blank"
      end

      should "not complete the transition to scheduled_for_publishing" do
        assert_equal 'ready', @edition.state
      end
    end

    context "when publish_at is specified" do
      setup do
        @edition = FactoryGirl.create(:edition, state: 'ready')
        @publish_when = 1.day.from_now
        @edition.schedule_for_publishing(@publish_when)
        @edition.reload
      end

      should "save publish_at against the edition" do
        assert_equal @publish_when.to_i, @edition.publish_at.to_i
      end

      should "complete the transition to scheduled_for_publishing" do
        assert_equal 'scheduled_for_publishing', @edition.state
      end
    end

    should "not allow scheduling at a time in the past" do
      edition = FactoryGirl.create(:edition, state: 'ready')

      edition.schedule_for_publishing(1.hour.ago)

      assert_includes edition.errors[:publish_at], "can't be a time in the past"
    end
  end

  context "when scheduled_for_publishing" do
    should "not allow editing fields like title" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)

      edition.title = 'a new title'

      refute edition.valid?
      assert_includes edition.errors.full_messages, "Editions scheduled for publishing can't be edited"
    end

    should "return false for #can_destroy?" do
      edition = FactoryGirl.build(:edition, :scheduled_for_publishing)
      refute edition.can_destroy?
    end

    should "return false for #can_create_new_edition?" do
      edition = FactoryGirl.build(:edition, :scheduled_for_publishing)
      refute edition.can_create_new_edition?
    end

    should "allow transition to published state" do
      edition = FactoryGirl.build(:edition, :scheduled_for_publishing)
      assert edition.can_publish?
    end
  end

  context "#cancel_scheduled_publishing" do
    should "remove the publish_at stored against the edition and transition back to ready" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
      edition.cancel_scheduled_publishing
      edition.reload

      assert_nil edition.publish_at
      assert_equal 'ready', edition.state
    end

    should "work with editions that have passed publish_at time" do
      edition = FactoryGirl.create(:edition, :scheduled_for_publishing)
      edition.update_attribute :publish_at, 2.days.ago

      edition.cancel_scheduled_publishing

      assert_equal 'ready', edition.reload.state
    end
  end
end
