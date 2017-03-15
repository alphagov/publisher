class RepublishWorker
  include Sidekiq::Worker

  def perform(edition_id)
    edition = Edition.find(edition_id)
    RepublishService.call(edition)
  end
end
