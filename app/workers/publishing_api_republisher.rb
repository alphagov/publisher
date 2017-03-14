class PublishingAPIRepublisher
  include Sidekiq::Worker

  def perform(edition_id)
    edition = Edition.find(edition_id)
    UpdateService.call(edition, 'republish')
    PublishService.call(edition, 'republish')
  end
end
