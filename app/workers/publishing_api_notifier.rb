class PublishingAPINotifier
  include Sidekiq::Worker

  def perform(edition_id, update_type = "normal")
    edition = Edition.find(edition_id)
    presenter = PublishedEditionPresenter.new(edition)
    document_for_publishing_api = presenter.render_for_publishing_api(republish: update_type == "republish")
    base_path = document_for_publishing_api[:base_path]

    Services.publishing_api.put_content_item(base_path, document_for_publishing_api)
  end
end
