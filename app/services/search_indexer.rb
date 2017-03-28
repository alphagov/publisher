class SearchIndexer
  FORMATS_NOT_TO_INDEX = %w(business_support completed_transaction)

  attr_reader :edition
  delegate :slug, to: :edition

  def initialize(edition)
    @edition = edition
  end

  def self.call(edition)
    new(edition).call
  end

  def call
    if indexable?
      Services.rummager.add_document(type, document_id, payload)
    end
  end

private

  def kind
    edition.artefact.kind
  end

  def indexable?
    FORMATS_NOT_TO_INDEX.exclude?(kind) || EXCEPTIONAL_SLUGS.include?(slug)
  end

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
