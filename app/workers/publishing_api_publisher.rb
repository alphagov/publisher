require 'services'

class PublishingAPIPublisher < WorkerBase
  def call(edition_id, update_type = "minor")
    edition = Edition.find(edition_id)
    content_id = edition.artefact.content_id

    Services.publishing_api.publish(content_id, update_type)

    presenter = EditionLinksPresenter.new(edition)
    Services.publishing_api.patch_links(content_id, presenter.payload)
  end
end
