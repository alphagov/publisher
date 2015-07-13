require "test_helper"

class EditionTaggerTest < ActiveSupport::TestCase
  test "should assign tag to a single Edition" do
    edition = FactoryGirl.create(:edition, state: :published)
    EditionTagger.new([{slug: edition.slug, tag: "foo"}], Logger.new(STDOUT)).run

    assert_equal ["foo"], edition.published_edition.browse_pages
  end

  test "should assign tags to draft edition when no published edition" do
    draft_edition = FactoryGirl.create(:edition,
      state: :draft, slug: "/a-slug")

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

    EditionTagger.new([{slug: "/a-slug", tag: "foo"}], Logger.new(STDOUT)).run
    archived_edition.reload
    draft_edition.reload
    published_edition.reload

    assert_equal [], archived_edition.browse_pages
    assert_equal ["foo"], draft_edition.browse_pages
    assert_equal ["foo"], published_edition.browse_pages
  end

  test "should not add duplicate tags" do
    edition = FactoryGirl.create(:edition, state: :published, browse_pages: ["foo"])
    EditionTagger.new([{slug: edition.slug, tag: "foo"}], Logger.new(STDOUT)).run

    assert_equal ["foo"], edition.published_edition.browse_pages
  end
end
