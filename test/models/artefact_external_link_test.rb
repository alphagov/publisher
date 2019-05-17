require "test_helper"

class ArtefactExternalLinkTest < ActiveSupport::TestCase
  context "validating a link" do
    should "not be valid without a title or URL" do
      assert_not ArtefactExternalLink.new.valid?
    end

    should "not be valid with URL missing" do
      assert_not ArtefactExternalLink.new(title: "Foo").valid?
    end

    should "not be valid with title missing" do
      assert_not ArtefactExternalLink.new(url: "http://bar.com").valid?
    end

    should "be valid with both fields supplied" do
      link = ArtefactExternalLink.new(title: "Foo", url: "http://bar.com")
      assert link.valid?
    end

    should "only be valid if the URL is valid" do
      link = ArtefactExternalLink.new(title: "Foo", url: "notreal://foo.com")
      assert_not link.valid?
    end

    should "be valid with an https URL" do
      link = ArtefactExternalLink.new(title: "Foo", url: "https://bar.com")
      assert link.valid?
    end
  end
end
