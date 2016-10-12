require 'integration_test_helper'

class TaggingTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables

    @edition = FactoryGirl.create(:guide_edition)
    @artefact = @edition.artefact
    @artefact.external_links = []
    @content_id = @edition.artefact.content_id
  end

  context "Tagging to linkables" do
    should "tag to browse pages" do
      visit edition_path(@edition)
      switch_tab 'Tagging'

      select 'Tax / VAT', from: 'Mainstream browse pages'
      select 'Tax / RTI (draft)', from: 'Mainstream browse pages'

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          topics: [],
          organisations: [],
          mainstream_browse_pages: ["CONTENT-ID-RTI", "CONTENT-ID-VAT"],
          parent: [],
        },
        previous_version: 0
      )
    end

    should "tag to topics" do
      visit edition_path(@edition)
      switch_tab 'Tagging'

      select 'Oil and Gas / Fields', from: 'Topics'
      select 'Oil and Gas / Distillation (draft)', from: 'Topics'

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          topics: ['CONTENT-ID-DISTILL', 'CONTENT-ID-FIELDS'],
          organisations: [],
          mainstream_browse_pages: [],
          parent: [],
        },
        previous_version: 0
      )
    end

    should "tag to organisations" do
      visit edition_path(@edition)
      switch_tab 'Tagging'

      select 'Student Loans Company', from: 'Organisations'

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          topics: [],
          organisations: ["9a9111aa-1db8-4025-8dd2-e08ec3175e72"],
          mainstream_browse_pages: [],
          parent: [],
        },
        previous_version: 0
      )
    end

    should "tag to parent" do
      visit edition_path(@edition)
      switch_tab 'Tagging'

      select 'Tax / RTI', from: 'Breadcrumb'

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          topics: [],
          organisations: [],
          mainstream_browse_pages: [],
          parent: ['CONTENT-ID-RTI'],
        },
        previous_version: 0
      )
    end

    should "mutate existing tags" do
      publishing_api_has_links(
        "content_id" => @content_id,
        "links" => {
          topics: ['CONTENT-ID-WELLS'],
          mainstream_browse_pages: ['CONTENT-ID-RTI'],
          parent: ['CONTENT-ID-RTI'],
        },
      )

      visit edition_path(@edition)
      switch_tab 'Tagging'

      select 'Tax / RTI (draft)', from: 'Mainstream browse pages'
      select 'Tax / VAT', from: 'Mainstream browse pages'

      select 'Tax / Capital Gains Tax', from: 'Breadcrumb'
      select 'Oil and Gas / Fields', from: 'Topics'

      save_tags_and_assert_success

      assert_publishing_api_patch_links(
        @content_id,
        links: {
          topics: ['CONTENT-ID-FIELDS', 'CONTENT-ID-WELLS'],
          organisations: [],
          mainstream_browse_pages: ['CONTENT-ID-RTI', 'CONTENT-ID-VAT'],
          parent: ['CONTENT-ID-CAPITAL'],
        },
        previous_version: 0
      )
    end

    should "User makes a conflicting change" do
      publishing_api_has_links(
        "content_id" => @content_id,
        "links" => {
          topics: ['CONTENT-ID-WELLS'],
          mainstream_browse_pages: ['CONTENT-ID-RTI'],
          parent: ['CONTENT-ID-RTI'],
        },
      )

      visit edition_path(@edition)

      switch_tab 'Tagging'

      select 'Oil and Gas / Fields', from: 'Topics'

      stub_request(:patch, "#{PUBLISHING_API_V2_ENDPOINT}/links/#{@content_id}")
        .to_return(status: 409)

      save_tags

      assert page.has_content?('Somebody changed the tags before you could')
    end
  end

  context "Getting links" do
    should "handle 404s from publishing-api (e.g. straight after a new artefact is created)" do
      stub_request(:get, "#{PUBLISHING_API_V2_ENDPOINT}/links/#{@content_id}")
        .to_return(status: 404)

      visit edition_path(@edition)

      assert page.has_content?('Test guide')
    end
  end

  context "Tagging to external links" do
    should "add new external links when the item is not tagged" do
      visit edition_path(@edition)
      switch_tab 'Related external links'

      assert 0, @artefact.external_links.count

      click_on "Add related external link"
      within ".related-external-links" do
        fill_in "Title", with: "GOVUK"
        fill_in "URL", with: "https://www.gov.uk"
      end

      click_on "Save links"
      @artefact.reload

      assert_equal 1, @artefact.external_links.length
      assert_equal "GOVUK", @artefact.external_links.first.title
    end

    should "not add duplicate external links" do # check both title and url
      @artefact.external_links = [{ title: "GOVUK", url: "https://www.gov.uk" }]
      assert 1, @artefact.external_links.count

      visit edition_path(@edition)
      switch_tab 'Related external links'
      click_on "Add related external link"

      within ".related-external-links" do
        fill_in "Title", with: "GOVUK", match: :first
        fill_in "URL", with: "https://www.gov.uk", match: :first
      end

      click_on "Save links"
      @artefact.reload

      assert_equal 1, @artefact.external_links.length
    end

    should "not save when no links are added" do
      visit edition_path(@edition)
      switch_tab 'Related external links'
      click_on "Save links"

      assert page.has_content?("There aren't any external related links yet")
    end

    should "delete links" do
      @artefact.external_links = [{ title: "GOVUK", url: "https://www.gov.uk" }]
      assert 1, @artefact.external_links.count

      visit edition_path(@edition)
      switch_tab "Related external links"
      click_on "Remove this URL"
      click_on "Save links"
      @artefact.reload

      assert_equal 0, @artefact.external_links.length
    end

    should "not add invalid links" do
      visit edition_path(@edition)
      switch_tab 'Related external links'

      click_on "Add related external link"
      within ".related-external-links" do
        fill_in "Title", with: "GOVUK"
        fill_in "URL", with: "an invalid url"
      end

      click_on "Save links"
      @artefact.reload

      assert_equal 0, @artefact.external_links.length
    end
  end
end
