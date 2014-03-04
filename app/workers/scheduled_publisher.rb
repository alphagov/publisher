class ScheduledPublisher
  include Sidekiq::Worker

  def perform(user_id, edition_id, activity_details)
    actor, edition = User.find(user_id), Edition.find(edition_id)
    actor.publish(edition, activity_details)
  end
end
