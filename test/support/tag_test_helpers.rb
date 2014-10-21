require 'gds_api/test_helpers/content_api'

module TagTestHelpers
  include GdsApi::TestHelpers::ContentApi

  def stub_collections
    stub_browse_pages
    stub_topics
  end

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

  def stub_topics
    oil_and_gas = {slug: 'oil-and-gas', title: 'Oil and Gas'}

    live_topics = [
      oil_and_gas,
      {slug: 'oil-and-gas/wells', title: 'Wells', parent: oil_and_gas},
      {slug: 'oil-and-gas/fields', title: 'Fields', parent: oil_and_gas}
    ]

    draft_topics = [
      {slug: 'oil-and-gas/distillation', title: 'Distillation', parent: oil_and_gas}
    ]

    content_api_has_draft_and_live_tags(type: 'specialist_sector', live: live_topics, draft: draft_topics)
  end
end
