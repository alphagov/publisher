class UpdateWorker
  include Sidekiq::Worker

  def perform(edition_id)
    edition = Edition.find(edition_id)
    UpdateService.call(edition)
  end
end
