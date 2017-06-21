require 'test_helper'

class SlugTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field "name", type: String
    field "slug", type: String
    field "kind", type: String

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true, slug: true
  end

  def document_with_slug(slug, override_options = {})
    default_options = {
      name: "Test",
      slug: slug
    }
    Dummy.new(default_options.merge(override_options))
  end

  context "default slugs" do
    should "reject url paths" do
      refute document_with_slug("path/not-allowed").valid?
    end

    should "allow a normal slug" do
      assert document_with_slug("normal-slug").valid?
    end

    should "allow consecutive dashes in a slug" do
      # Gems like friendly_id use -- to de-dup slug collisions
      assert document_with_slug("normal-slug--1").valid?
    end
  end

  context "Foreign travel advice pages" do
    should "allow a travel-advice page to start with 'foreign-travel-advice/'" do
      assert document_with_slug("foreign-travel-advice/aruba", kind: "travel-advice").valid?
    end

    should "not allow other types to start with 'foreign-travel-advice/'" do
      refute document_with_slug("foreign-travel-advice/aruba", kind: "answer").valid?
    end
  end

  context "Help pages" do
    should "must start with help/" do
      refute document_with_slug("test", kind: "help_page").valid?
      assert document_with_slug("help/test", kind: "help_page").valid?
    end

    should "not allow non-help pages to start with help/" do
      refute document_with_slug("help/test", kind: "answer").valid?
    end
  end

  context "Done pages" do
    should "start with done/" do
      refute document_with_slug("test", kind: "completed_transaction").valid?
      assert document_with_slug("done/test", kind: "completed_transaction").valid?
    end

    should "not allow non-done pages to start with done/" do
      refute document_with_slug("done/test", kind: "answer").valid?
    end
  end

  context "Manual pages" do
    should "allow slugs starting guidance/" do
      refute document_with_slug("manuals/a-manual", kind: "manual").valid?
      assert document_with_slug("guidance/a-manual", kind: "manual").valid?
    end

    should "allow two or three path parts" do
      refute document_with_slug("guidance", kind: "manual").valid?
      assert document_with_slug("guidance/a-manual", kind: "manual").valid?
    end

    should "not allow invalid path segments" do
      refute document_with_slug("guidance/bad.manual.slug", kind: "manual").valid?
    end
  end
end
