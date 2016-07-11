require 'services'

class PublishingAPIUpdater < WorkerBase
  def call(edition_id, update_type = "minor")
    edition = Edition.find(edition_id)
    presenter = PublishedEditionPresenter.new(edition)
    payload = presenter.render_for_publishing_api(republish: update_type == "republish")

    Services.publishing_api.put_content(edition.artefact.content_id, payload)
  end
end
