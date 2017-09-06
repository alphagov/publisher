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
    if indexable?
      Services.rummager.add_document(type, document_id, payload)
    end
  end

private

  def kind
    edition.artefact.kind
  end

  def indexable?
    kind != "completed_transaction"
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
