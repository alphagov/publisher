class SearchIndexer
  attr_reader :edition
  delegate :slug, to: :edition

  def initialize(edition)
    @edition = edition
  end

  def self.call(edition)
    new(edition).call
  end

  def call
    Services.rummager.add_document(type, document_id, payload)
  end

private

  def type
    'edition'
  end

  def document_id
    "/#{slug}"
  end

  def payload
    SearchPayloadPresenter.present(edition)
  end
end
