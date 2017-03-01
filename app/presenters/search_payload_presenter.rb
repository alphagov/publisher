class SearchPayloadPresenter
  attr_reader :registerable_edition
  delegate :slug,
           :title,
           :description,
           :indexable_content,
           :public_timestamp,
           :artefact,
           :format,
           to: :registerable_edition

  def initialize(registerable_edition)
    @registerable_edition = registerable_edition
  end

  def self.present(registerable_edition)
    new(registerable_edition).present
  end

  def present
    {
      content_id: artefact.content_id,
      rendering_app: publishing_api_payload.fetch(:rendering_app),
      publishing_app: publishing_api_payload.fetch(:publishing_app),
      format: format.underscore,
      title: title,
      description: description,
      indexable_content: indexable_content,
      link: "/#{slug}",
      public_timestamp: public_timestamp,
      content_store_document_type: publishing_api_payload.fetch(:document_type),
    }
  end

  def publishing_api_payload
    @publishing_api_payload ||= begin
      presenter = EditionPresenterFactory.get_presenter(registerable_edition)
      presenter.render_for_publishing_api
    end
  end
end
