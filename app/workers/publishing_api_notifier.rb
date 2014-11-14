require "gds_api/publishing_api"

class PublishingAPINotifier
  include Sidekiq::Worker

  def perform(edition_id)
    edition = Edition.find(edition_id)
    presenter = PublishedEditionPresenter.new(edition)
    document_for_publishing_api = presenter.render_for_publishing_api(republish: false)
    base_path = document_for_publishing_api[:base_path]

    publishing_api.put_content_item(base_path, document_for_publishing_api)
  end

private

  def publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(Plek.find("publishing-api"))
  end
end
