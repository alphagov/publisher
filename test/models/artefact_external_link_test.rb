require "test_helper"

class ArtefactExternalLinkTest < ActiveSupport::TestCase
  context "validating a link" do
    setup do
      @artefact = FactoryBot.create(:artefact)
    end

    should "not be valid without a title or URL" do
      assert_not ArtefactExternalLink.new.valid?
    end

    should "not be valid with URL missing" do
      assert_not ArtefactExternalLink.new(title: "Foo", artefact: @artefact).valid?
    end

    should "not be valid with title missing" do
      assert_not ArtefactExternalLink.new(url: "http://bar.com", artefact: @artefact).valid?
    end

    should "be valid with both fields supplied" do
      link = ArtefactExternalLink.new(title: "Foo", url: "http://bar.com", artefact: @artefact)
      assert link.valid?
    end

    should "only be valid if the URL is valid" do
      link = ArtefactExternalLink.new(title: "Foo", url: "notreal://foo.com", artefact: @artefact)
      assert_not link.valid?
    end

    should "be valid with an https URL" do
      link = ArtefactExternalLink.new(title: "Foo", url: "https://bar.com", artefact: @artefact)
      assert link.valid?
    end

    should "trim whitespace from URLs" do
      link = ArtefactExternalLink.new(title: "Test", url: " http://example.org ", artefact: @artefact)
      assert link.valid?
      assert link.url == "http://example.org"
    end
  end
end
