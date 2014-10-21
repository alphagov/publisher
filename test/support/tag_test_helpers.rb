require 'gds_api/test_helpers/content_api'

module TagTestHelpers
  include GdsApi::TestHelpers::ContentApi

  def stub_browse_pages
    tax = {slug: 'tax', title: 'Tax'}

    live_browse_pages = [
      tax,
      {slug: 'tax/vat', title: 'VAT', parent: tax},
      {slug: 'tax/capital-gains', title: 'Capital Gains Tax', parent: tax}
    ]

    draft_browse_pages = [
      {slug: 'tax/rti', title: 'RTI', parent: tax}
    ]

    content_api_has_draft_and_live_tags(type: 'section', live: live_browse_pages, draft: draft_browse_pages)
  end
end
