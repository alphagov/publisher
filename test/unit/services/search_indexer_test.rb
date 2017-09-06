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
    search_index_presenter = SearchIndexPresenter.new(edition)

    Services.rummager.expects(:add_document).with(
      'edition',
      "/#{edition.slug}",
      content_id: "content-id",
      rendering_app: "frontend",
      publishing_app: "publisher",
      format: "answer",
      title: "A title",
      description: "An overview",
      indexable_content: "Indexable content",
      link: "/#{edition.slug}",
      public_timestamp: search_index_presenter.public_timestamp,
      content_store_document_type: "answer",
    )

    SearchIndexer.call(search_index_presenter)
  end

  def test_completed_transactions_are_not_indexed
    artefact = FactoryGirl.create(
      :artefact,
      kind: "completed_transaction",
      slug: "done/something",
      content_id: "content-id"
    )

    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)
    search_index_presenter = SearchIndexPresenter.new(edition)

    Services.rummager.expects(:add_document).never

    SearchIndexer.call(search_index_presenter)
  end

  def test_rummager_document_type_matches_content_store
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

    presenter = EditionPresenterFactory.get_presenter(edition)
    document_type = presenter.render_for_publishing_api[:document_type]

    search_index_presenter = SearchIndexPresenter.new(edition)

    Services.rummager.expects(:add_document).with(
      'edition',
      "/#{edition.slug}",
      has_entry(
        content_store_document_type: document_type,
      )
    )

    SearchIndexer.call(search_index_presenter)
  end

  def test_indexing_licences_to_rummager_includes_licence_identifier_and_short_description
    artefact = FactoryGirl.create(
      :artefact,
      kind: "licence",
      content_id: "content-id",
    )
    edition = FactoryGirl.create(
      :licence_edition,
      title: "A title",
      overview: "An overview",
      licence_identifier: '1258-4-1',
      licence_short_description: 'This is a licence short description.',
      panopticon_id: artefact.id,
    )
    search_index_presenter = SearchIndexPresenter.new(edition)

    Services.rummager.expects(:add_document).with(
      'edition',
      "/#{edition.slug}",
      content_id: "content-id",
      rendering_app: "frontend",
      publishing_app: "publisher",
      format: "licence",
      title: "A title",
      description: "An overview",
      indexable_content: "This is a licence short description. This is a licence overview.",
      link: "/#{edition.slug}",
      public_timestamp: search_index_presenter.public_timestamp,
      content_store_document_type: "licence",
      licence_identifier: "1258-4-1",
      licence_short_description: 'This is a licence short description.'
    )

    SearchIndexer.call(search_index_presenter)
  end
end
