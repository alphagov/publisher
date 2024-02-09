class UpdateService
  def self.call(edition, republish: false)
    Rails.logger.info("Preparing to send draft edition to publishing-api with title: #{edition.title}")
    presenter = EditionPresenterFactory.get_presenter(edition)
    payload = presenter.render_for_publishing_api(republish:)
    Services.publishing_api.put_content(edition.content_id, payload)
    Rails.logger.info("Draft edition sent to publishing-api with title: #{edition.title}")
  end
end
