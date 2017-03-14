class UpdateService
  def self.call(edition, update_type = "minor")
    presenter = EditionPresenterFactory.get_presenter(edition)
    payload = presenter.render_for_publishing_api(republish: update_type == "republish")
    Services.publishing_api.put_content(edition.content_id, payload)
  end
end
