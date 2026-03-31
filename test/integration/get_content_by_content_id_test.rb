require "integration_test_helper"

class GetContentByContentIdTest < IntegrationTest
  def setup
    login_as_stub_user
    @artefact = FactoryBot.create(:artefact, name: "browser extension test")
  end

  context "Content items that have only one edition, in the draft state" do
    should "redirect to the find_content page and display the edition" do
      create_draft_edition
      visit "by-content-id/#{@draft_edition.content_id}"

      assert_current_path find_content_path(search_text: @draft_edition.slug)
      assert page.has_content?("some title")
    end
  end

  context "Content items that have only one edition, in the published state " do
    should "redirect to the find_content page and display the edition" do
      create_published_edition
      visit "by-content-id/#{@published_edition.content_id}"

      assert_current_path find_content_path(search_text: @published_edition.slug)
      assert page.has_content?("some different title")
    end
  end

  context "Content items that have one edition in the published state and one item in draft state " do
    should "redirect to the find_content page and display both editions" do
      create_published_edition
      create_draft_edition
      visit "by-content-id/#{@published_edition.content_id}"

      assert_current_path find_content_path(search_text: @published_edition.slug)
      assert page.has_content?("some title")
      assert page.has_content?("some different title")
    end
  end

private

  def create_draft_edition
    @draft_edition = FactoryBot.create(:edition, state: :draft, title: "some title", panopticon_id: @artefact.id, slug: "browser-extension-test")
  end

  def create_published_edition
    @published_edition = FactoryBot.create(:edition, state: :published, title: "some different title", panopticon_id: @artefact.id, slug: "browser-extension-test")
  end
end
