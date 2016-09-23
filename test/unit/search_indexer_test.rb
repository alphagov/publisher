require "test_helper"

class SearchIndexerTest < ActiveSupport::TestCase
  def test_indexing_to_rummager
    artefact = FactoryGirl.create(
      :artefact,
      content_id: "content-id",
    )
    edition = FactoryGirl.create(
      :answer_edition,
      title: "A title",
      overview: "An overview",
      panopticon_id: artefact.id,
      body: "Indexable content",
    )
    registerable_edition = RegisterableEdition.new(edition)

    Services.rummager.expects(:add_document).with(
      'edition',
      "/#{edition.slug}",
      content_id: "content-id",
      rendering_app: "publisher",
      publishing_app: "publisher",
      format: "answer",
      title: "A title",
      description: "An overview",
      indexable_content: "Indexable content",
      link: "/#{edition.slug}",
      public_timestamp: registerable_edition.public_timestamp,
    )

    SearchIndexer.call(registerable_edition)
  end
end
