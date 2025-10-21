require "legacy_integration_test_helper"

class TaggingTest < LegacyJavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_publishing_api_has_lookups({})
    stub_events_for_all_content_ids
    stub_users_from_signon_api

    @edition = FactoryBot.create(:guide_edition, title: "Test guide")
    @artefact = @edition.artefact
    @artefact.external_links = []
    @content_id = @edition.artefact.content_id
  end

  context "Tagging to linkables" do
    should "tag to browse pages" do
      visit_edition @edition
      switch_tab "Tagging"

      select2 "Tax / VAT", "Tax / RTI (draft)", from: "Mainstream browse pages"

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          organisations: [],
          mainstream_browse_pages: %w[CONTENT-ID-RTI CONTENT-ID-VAT],
          ordered_related_items: [],
          parent: [],
        },
        previous_version: 0,
      )
    end

    should "tag to organisations" do
      visit_edition @edition
      switch_tab "Tagging"

      select2 "Student Loans Company", from: "Organisations"

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          organisations: %w[9a9111aa-1db8-4025-8dd2-e08ec3175e72],
          mainstream_browse_pages: [],
          ordered_related_items: [],
          parent: [],
        },
        previous_version: 0,
      )
    end

    should "tag to related content items" do
      expanded_links_url = "#{Plek.find('publishing-api')}/v2/expanded-links/#{@edition.artefact.content_id}?locale=#{@edition.artefact.language}&generate=true"
      stub_request(:get, expanded_links_url)
        .to_return(status: 200,
                   body: {
                     "content_id" => @edition.artefact.content_id,
                     "expanded_links" => {
                       "ordered_related_items" => [
                         {
                           "content_id" => "CONTENT-ID-VAT-RETURNS",
                           "base_path" => "/vat-returns",
                           "internal_name" => "VAT Returns",
                         },
                       ],
                     },
                   }.to_json)

      visit_edition @edition
      switch_tab "Tagging"

      ordered_related_items_fields = all(
        'input[name="tagging_legacy_tagging_update_form[ordered_related_items][]"]',
      )

      assert ordered_related_items_fields[0].value, "/vat-returns"

      find(".js-path-field").set("/reclaim-vat")

      # Web request that JS makes to check the path is a valid GOV.UK base path
      stub_publishing_api_has_lookups("/reclaim-vat" => "CONTENT-ID-RECLAIM-VAT")
      click_on "Add related item"

      within :xpath, '//ul[contains(@class,"js-base-path-list")]/li[1]' do
        assert page.has_field?("tagging_legacy_tagging_update_form[ordered_related_items][]", with: "/vat-returns")
      end

      within :xpath, '//ul[contains(@class,"js-base-path-list")]/li[2]' do
        assert page.has_field?("tagging_legacy_tagging_update_form[ordered_related_items][]", with: "/reclaim-vat")
      end

      stub_publishing_api_has_lookups(
        "/vat-returns" => "CONTENT-ID-VAT-RETURNS",
        "/reclaim-vat" => "CONTENT-ID-RECLAIM-VAT",
      )

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          organisations: [],
          mainstream_browse_pages: [],
          ordered_related_items: %w[CONTENT-ID-VAT-RETURNS CONTENT-ID-RECLAIM-VAT],
          parent: [],
        },
        previous_version: 0,
      )
    end

    should "show an error state when attempting to tag to an invalid related link" do
      visit_edition @edition
      switch_tab "Tagging"

      find(".js-path-field").set("/a-page-that-does-not-exist")
      click_on "Add related item"

      assert page.has_content?("Not a known URL or path on GOV.UK")
    end

    should "tag to parent" do
      visit_edition @edition
      switch_tab "Tagging"

      select2 "Tax / RTI", from: "Breadcrumb"

      save_tags_and_assert_success
      assert_publishing_api_patch_links(
        @content_id,
        links: {
          organisations: [],
          mainstream_browse_pages: [],
          ordered_related_items: [],
          parent: %w[CONTENT-ID-RTI],
        },
        previous_version: 0,
      )
    end

    should "mutate existing tags" do
      expanded_links_url = "#{Plek.find('publishing-api')}/v2/expanded-links/#{@content_id}?locale=#{@edition.artefact.language}&generate=true"
      stub_request(:get, expanded_links_url)
        .to_return(status: 200,
                   body: {
                     "content_id" => @content_id,
                     "expanded_links" => {
                       "mainstream_browse_pages" => [
                         {
                           "content_id" => "CONTENT-ID-RTI",
                           "base_path" => "/browse/tax/rti",
                           "internal_name" => "Tax / RTI",
                         },
                       ],
                       "parent" => [
                         {
                           "content_id" => "CONTENT-ID-RTI",
                           "document_type" => "mainstream_browse_pages",
                         },
                       ],
                     },
                   }.to_json)

      visit_edition @edition
      switch_tab "Tagging"

      select2_clear from: "Mainstream browse pages"
      select2 "Tax / RTI (draft)", "Tax / VAT", from: "Mainstream browse pages"

      select2 "Tax / Capital Gains Tax", from: "Breadcrumb"

      save_tags_and_assert_success

      assert_publishing_api_patch_links(
        @content_id,
        links: {
          organisations: [],
          mainstream_browse_pages: %w[CONTENT-ID-RTI CONTENT-ID-VAT],
          ordered_related_items: [],
          parent: %w[CONTENT-ID-CAPITAL],
        },
        previous_version: 0,
      )
    end

    should "User makes a conflicting change" do
      stub_publishing_api_has_links(
        "content_id" => @content_id,
        "links" => {
          mainstream_browse_pages: %w[CONTENT-ID-RTI],
          parent: %w[CONTENT-ID-RTI],
        },
      )

      visit_edition @edition

      switch_tab "Tagging"

      select2 "Tax / RTI", from: "Mainstream browse pages"

      stub_request(:patch, "#{PUBLISHING_API_V2_ENDPOINT}/links/#{@content_id}")
        .to_return(status: 409)

      save_tags

      assert page.has_content?("Somebody changed the tags before you could")
    end
  end

  context "Getting links" do
    should "handle 404s from publishing-api (e.g. straight after a new artefact is created)" do
      stub_request(:get, "#{PUBLISHING_API_V2_ENDPOINT}/links/#{@content_id}")
        .to_return(status: 404)

      visit_edition @edition

      assert page.has_content?("Test guide")
    end
  end

  context "Tagging to external links" do
    should "add new external links when the item is not tagged" do
      visit_edition @edition
      switch_tab "Related external links"

      assert 0, @artefact.external_links.count

      click_on "Add related external link"
      within ".related-external-links" do
        fill_in "Title", with: "GOVUK"
        fill_in "URL", with: "https://www.gov.uk"
      end

      click_on "Save links"
      assert page.has_content?("External links have been saved")
      @artefact.reload

      assert_equal 1, @artefact.external_links.length
      assert_equal "GOVUK", @artefact.external_links.first.title
    end

    should "not add duplicate external links" do # check both title and url
      @artefact.external_links = [ArtefactExternalLink.build({ title: "GOVUK", url: "https://www.gov.uk" })]
      assert 1, @artefact.external_links.count

      visit_edition @edition
      switch_tab "Related external links"
      click_on "Add related external link"

      within ".related-external-links" do
        fill_in "Title", with: "GOVUK", match: :first
        fill_in "URL", with: "https://www.gov.uk", match: :first
      end

      click_on "Save links"
      assert page.has_content?("External links have been saved")
      @artefact.reload

      assert_equal 1, @artefact.external_links.length
    end

    should "not save when no links are added" do
      visit_edition @edition
      switch_tab "Related external links"
      click_on "Save links"

      assert page.has_content?("There aren't any external related links yet")
    end

    should "delete links" do
      @artefact.external_links = [ArtefactExternalLink.build({ title: "GOVUK", url: "https://www.gov.uk" })]
      assert 1, @artefact.external_links.count

      visit_edition @edition
      switch_tab "Related external links"
      click_on "Remove this URL"
      click_on "Save links"
      assert page.has_content?("External links have been saved")
      @artefact.reload

      assert_equal 0, @artefact.external_links.length
    end

    should "not add invalid links" do
      visit_edition @edition
      switch_tab "Related external links"

      click_on "Add related external link"
      within ".related-external-links" do
        fill_in "Title", with: "GOVUK"
        fill_in "URL", with: "an invalid url"
      end

      click_on "Save links"
      assert page.has_content?("External links URL is invalid")
      @artefact.reload

      assert_equal 0, @artefact.external_links.length
    end
  end
end
