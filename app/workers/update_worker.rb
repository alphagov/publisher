class UpdateWorker
  include Sidekiq::Worker

  def perform(edition_id, update_type = "minor")
    edition = Edition.find(edition_id)
    UpdateService.call(edition, update_type)
  end
end
