require "integration_test_helper"

class GetContentByContentIdTest < IntegrationTest
  def setup
    login_as_stub_user
    @artefact = FactoryBot.create(:artefact, name: "browser extension test")
    @test_strategy = Flipflop::FeatureSet.current.test!
  end

  context "Content items that have only one edition, in the draft state" do
    should "show main list as empty and 'filter by status' counts all as zero except for 'Drafts'" do
      filter_by_status = ["Filter by Status", "Drafts 1", "In review 0", "Amends needed 0", "Out for fact check 0", "Fact check received 0", "Ready 0", "Scheduled 0", "Published 0", "Archived 0"]
      create_draft_edition
      visit "by-content-id/#{@draft_edition.content_id}"

      sidebar_filter_by_status = find_all(".nav-list")[0]
      within sidebar_filter_by_status do
        statuses = find_all("li")
        statuses.each do |status|
          assert filter_by_status.include?(status.text)
        end
      end

      assert page.has_no_css?("#publication-list-container table tbody tr")
      assert page.has_no_content?("some title")
    end
  end

  context "Content items that have only one edition, in the published state " do
    should "show main list with a single edition and a 'Create new edition' button and 'filter by status' counts all as zero except for 'Published'" do
      filter_by_status = ["Filter by Status", "Drafts 0", "In review 0", "Amends needed 0", "Out for fact check 0", "Fact check received 0", "Ready 0", "Scheduled 0", "Published 1", "Archived 0"]
      create_published_edition
      visit "by-content-id/#{@published_edition.content_id}"

      sidebar_filter_by_status = find_all(".nav-list")[0]
      within sidebar_filter_by_status do
        statuses = find_all("li")
        statuses.each do |status|
          assert filter_by_status.include?(status.text)
        end
      end

      assert page.has_css?("#publication-list-container table tbody tr")
      assert page.has_content?("some title")
      assert page.has_link?("Create new edition")
    end
  end

  context "Content items that have one edition in the published state and one item in draft state " do
    should "show main list with a single edition and a 'Edit newer edition' button and 'filter by status' counts all as zero except for 'Published' and 'Draft'" do
      filter_by_status = ["Filter by Status", "Drafts 1", "In review 0", "Amends needed 0", "Out for fact check 0", "Fact check received 0", "Ready 0", "Scheduled 0", "Published 1", "Archived 0"]
      create_published_edition
      create_draft_edition
      visit "by-content-id/#{@published_edition.content_id}"

      sidebar_filter_by_status = find_all(".nav-list")[0]
      within sidebar_filter_by_status do
        statuses = find_all("li")
        statuses.each do |status|
          assert filter_by_status.include?(status.text)
        end
      end

      assert page.has_css?("#publication-list-container table tbody tr")
      assert page.has_content?("some title")
      assert page.has_link?("Edit newer edition")
    end
  end

private

  def create_draft_edition
    @draft_edition = FactoryBot.create(:edition, state: :draft, title: "some title", panopticon_id: @artefact.id, slug: "browser-extension-test")
  end

  def create_published_edition
    @published_edition = FactoryBot.create(:edition, state: :published, title: "some title", panopticon_id: @artefact.id, slug: "browser-extension-test")
  end
end
