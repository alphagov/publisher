require "test_helper"

class EditionTaggerTest < ActiveSupport::TestCase
  setup do
    @logger = stub("logger")
    @logger.stubs(:info)
  end

  def mock_registerer(slug)
    mock_slug_registerer = stub("PublishedSlugRegisterer")
    PublishedSlugRegisterer.stubs(:new)
                           .with(@logger, [slug])
                           .returns(mock_slug_registerer)
    mock_slug_registerer.expects(:run).returns(true)
  end

  test "should assign tag to a single Edition" do
    edition = FactoryGirl.create(:edition, state: :published)
    mock_registerer(edition.slug)

    EditionTagger.new([{slug: edition.slug, tag: "foo"}], @logger).run

    assert_equal ["foo"], edition.published_edition.browse_pages
  end

  test "should assign tags to draft edition when no published edition" do
    draft_edition = FactoryGirl.create(:edition,
      state: :draft, slug: "/a-slug")
    mock_registerer("/a-slug")

    EditionTagger.new([{slug: "/a-slug", tag: "foo"}], @logger).run
    draft_edition.reload

    assert_equal ["foo"], draft_edition.browse_pages
  end

  test "should assign tags to published and draft Editions" do
    published_edition = FactoryGirl.create(:edition,
      state: :published, slug: "/a-slug")
    draft_edition = FactoryGirl.create(:edition,
      state: :draft, slug: "/a-slug",
      panopticon_id: published_edition.panopticon_id)
    archived_edition = FactoryGirl.create(:edition,
      state: :archived, slug: "/a-slug",
      panopticon_id: published_edition.panopticon_id)
    mock_registerer("/a-slug")

    EditionTagger.new([{slug: "/a-slug", tag: "foo"}], @logger).run
    archived_edition.reload
    draft_edition.reload
    published_edition.reload

    assert_equal [], archived_edition.browse_pages
    assert_equal ["foo"], draft_edition.browse_pages
    assert_equal ["foo"], published_edition.browse_pages
  end

  test "should not add duplicate tags" do
    edition = FactoryGirl.create(:edition, state: :published, browse_pages: ["foo"])
    mock_registerer(edition.slug)

    EditionTagger.new([{slug: edition.slug, tag: "foo"}], @logger).run

    assert_equal ["foo"], edition.published_edition.browse_pages
  end

  test "should add primary tags first" do
    edition = FactoryGirl.create(:edition, state: :published, browse_pages: ["foo"])
    mock_registerer(edition.slug)

    EditionTagger.new([{slug: edition.slug, tag: "bar", primary: "TRUE"}], @logger).run

    assert_equal ["bar", "foo"], edition.published_edition.browse_pages
  end

  test "should add non-primary tags last" do
    edition = FactoryGirl.create(:edition, state: :published, browse_pages: ["foo"])
    mock_registerer(edition.slug)

    EditionTagger.new([{slug: edition.slug, tag: "bar", primary: "FALSE"}], @logger).run

    assert_equal ["foo", "bar"], edition.published_edition.browse_pages
  end

  test "should error on typos in the `primary` column" do
    err = assert_raises(RuntimeError) {
      EditionTagger.new([{slug: "a-slug", tag: "bar", primary: "FASLE"}], @logger).run
    }
    assert_equal %{Invalid value for `primary`: FASLE}, err.message
  end
end
