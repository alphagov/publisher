require "test_helper"

class SearchIndexerTest < ActiveSupport::TestCase
  def test_indexing_to_rummager
    artefact = FactoryGirl.create(
      :artefact,
      kind: "answer",
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
      content_store_document_type: "answer",
    )

    SearchIndexer.call(registerable_edition)
  end

  def test_format_exceptions_are_not_indexed
    SearchIndexer::FORMATS_NOT_TO_INDEX.each do |format|
      artefact = FactoryGirl.create(
        :artefact, kind: format, content_id: "content-id",
      )
      edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)
      registerable_edition = RegisterableEdition.new(edition)

      Services.rummager.expects(:add_document).never

      SearchIndexer.call(registerable_edition)
    end
  end

  def test_exceptional_slugs_are_indexed_despite_their_format
    SearchIndexer::EXCEPTIONAL_SLUGS.each do |slug|
      artefact = FactoryGirl.create(
        :artefact,
        kind: SearchIndexer::FORMATS_NOT_TO_INDEX.first,
        content_id: "content-id",
      )
      edition = FactoryGirl.create(
        :answer_edition,
        slug: slug,
        panopticon_id: artefact.id,
      )

      registerable_edition = RegisterableEdition.new(edition)

      Services.rummager.expects(:add_document).once

      SearchIndexer.call(registerable_edition)
    end
  end
end
