require "test_helper"

class SlugTest < ActiveSupport::TestCase
  def document_with_slug(slug, kind: nil)
    if kind
      FactoryBot.build(:artefact, slug:, kind:)
    else
      FactoryBot.build(:artefact, slug:)
    end
  end

  context "default slugs" do
    should "reject url paths" do
      assert_not document_with_slug("path/not-allowed").valid?
    end

    should "allow a normal slug" do
      assert document_with_slug("normal-slug").valid?
    end

    should "allow consecutive dashes in a slug" do
      # Gems like friendly_id use -- to de-dup slug collisions
      assert document_with_slug("normal-slug--1").valid?
    end
  end

  context "Help pages" do
    should "must start with help/" do
      assert_not document_with_slug("test", kind: "help_page").valid?
      assert document_with_slug("help/test", kind: "help_page").valid?
    end

    should "not allow non-help pages to start with help/" do
      assert_not document_with_slug("help/test", kind: "answer").valid?
    end
  end

  context "Done pages" do
    should "start with done/" do
      assert_not document_with_slug("test", kind: "completed_transaction").valid?
      assert document_with_slug("done/test", kind: "completed_transaction").valid?
    end

    should "not allow non-done pages to start with done/" do
      assert_not document_with_slug("done/test", kind: "answer").valid?
    end
  end

  context "Manual pages" do
    should "allow slugs starting guidance/" do
      assert_not document_with_slug("manuals/a-manual", kind: "manual").valid?
      assert document_with_slug("guidance/a-manual", kind: "manual").valid?
    end

    should "allow two or three path parts" do
      assert_not document_with_slug("guidance", kind: "manual").valid?
      assert document_with_slug("guidance/a-manual", kind: "manual").valid?
    end

    should "not allow invalid path segments" do
      assert_not document_with_slug("guidance/bad.manual.slug", kind: "manual").valid?
    end
  end
end
