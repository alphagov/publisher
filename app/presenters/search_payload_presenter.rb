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
      rendering_app: "publisher",
      publishing_app: "publisher",
      format: format.underscore,
      title: title,
      description: description,
      indexable_content: indexable_content,
      link: "/#{slug}",
      public_timestamp: public_timestamp,
    }
  end
end
