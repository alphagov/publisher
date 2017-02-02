class PublishingAPIRepublisher
  include Sidekiq::Worker

  def perform(edition_id)
    PublishingAPIUpdater.new.perform(edition_id, 'republish')
    PublishingAPIPublisher.new.perform(edition_id, 'republish')
  end
end
