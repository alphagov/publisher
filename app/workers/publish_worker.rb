class PublishWorker
  include Sidekiq::Worker

  def perform(edition_id, update_type = nil)
    edition = Edition.find(edition_id)
    PublishService.call(edition, update_type)
  end
end
