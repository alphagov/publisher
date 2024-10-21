require "test_helper"
require "rake"

class PublishMissedScheduledEditionsTaskTest < ActiveSupport::TestCase
  def setup
    Rake::Task["editions:publish_missed_scheduled_editions"].reenable
  end

  test "publishes editions that have missed their scheduled publish time" do
    missed_edition = FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: 1.hour.from_now)
    missed_edition.update_attribute(:publish_at, 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations

    Rake::Task["editions:publish_missed_scheduled_editions"].invoke
    missed_edition.reload

    assert_equal "published", missed_edition.state
  end

  test "does not publish editions with publishing scheduled in the future" do
    edition_scheduled_in_future = FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: 1.hour.from_now)

    Rake::Task["editions:publish_missed_scheduled_editions"].invoke
    edition_scheduled_in_future.reload

    assert_equal "scheduled_for_publishing", edition_scheduled_in_future.state
  end
end
