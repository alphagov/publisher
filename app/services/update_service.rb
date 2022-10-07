class UpdateService
  def self.call(edition, republish: false)
    presenter = EditionPresenterFactory.get_presenter(edition)
    payload = presenter.render_for_publishing_api(republish: republish)
    Services.publishing_api.put_content(edition.content_id, payload)
  end
end
