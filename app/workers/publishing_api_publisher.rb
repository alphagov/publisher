require 'services'

class PublishingAPIPublisher
  include Sidekiq::Worker

  def perform(edition_id, update_type = "minor")
    edition = Edition.find(edition_id)
    content_id = edition.artefact.content_id

    Services.publishing_api.publish(content_id, update_type)
  end
end
