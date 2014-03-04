class ScheduledPublisher
  include Sidekiq::Worker

  # NOTE on ids: edition and actor id are enqueued
  # as String or else marshalling converts it to a hash
  def self.cancel_scheduled_publishing(cancel_edition_id)
    Sidekiq::ScheduledSet.new.select do |scheduled_job|
      scheduled_job.args[1] == cancel_edition_id
    end.map(&:delete)
  end

  def perform(user_id, edition_id, activity_details)
    actor, edition = User.find(user_id), Edition.find(edition_id)
    actor.publish(edition, activity_details)
  end
end
