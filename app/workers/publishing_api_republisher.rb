class PublishingAPIRepublisher
  include Sidekiq::Worker

  def perform(edition_id)
    edition = Edition.find(edition_id)
    PublishingAPIUpdater.new.perform(edition_id, 'republish')
    PublishService.call(edition, 'republish')
  end
end
