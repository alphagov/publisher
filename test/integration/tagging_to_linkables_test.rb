require 'integration_test_helper'

class TaggingToLinkablesTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables

    @edition = FactoryGirl.create(:guide_edition)
    @content_id = @edition.artefact.content_id
  end

  test "Tagging to browse pages" do
    visit edition_path(@edition)
    switch_tab 'Tagging'

    select 'Tax / VAT', from: 'Mainstream browse pages'
    select 'Tax / RTI (draft)', from: 'Mainstream browse pages'

    save_tags_and_assert_success
    assert_publishing_api_patch_links(
      @content_id,
      links: {
        topics: [],
        mainstream_browse_pages: ["CONTENT-ID-RTI", "CONTENT-ID-VAT"],
        parent: [],
      },
      previous_version: 0
    )
  end

  test "Tagging to topics" do
    visit edition_path(@edition)
    switch_tab 'Tagging'

    select 'Oil and Gas / Fields', from: 'Topics'
    select 'Oil and Gas / Distillation (draft)', from: 'Topics'

    save_tags_and_assert_success
    assert_publishing_api_patch_links(
      @content_id,
      links: {
        topics: ['CONTENT-ID-DISTILL', 'CONTENT-ID-FIELDS'],
        mainstream_browse_pages: [],
        parent: [],
      },
      previous_version: 0
    )
  end

  test "Tagging to parent" do
    visit edition_path(@edition)
    switch_tab 'Tagging'

    select 'Tax / RTI', from: 'Breadcrumb'

    save_tags_and_assert_success
    assert_publishing_api_patch_links(
      @content_id,
      links: {
        topics: [],
        mainstream_browse_pages: [],
        parent: ['CONTENT-ID-RTI'],
      },
      previous_version: 0
    )
  end

  test "Mutating existing tags" do
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
        mainstream_browse_pages: ['CONTENT-ID-RTI', 'CONTENT-ID-VAT'],
        parent: ['CONTENT-ID-CAPITAL'],
      },
      previous_version: 0
    )
  end

  test "User makes a conflicting change" do
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
