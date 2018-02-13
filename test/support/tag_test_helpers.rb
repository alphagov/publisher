require 'gds_api/test_helpers/publishing_api_v2'

module TagTestHelpers
  include GdsApi::TestHelpers::PublishingApiV2

  def stub_linkables
    stub_request(:get, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/links/.+})
      .to_return(status: 200, body: "{}", headers: {})

    publishing_api_has_linkables([
      { base_path: '/browse/tax/vat', internal_name: 'Tax / VAT', publication_state: 'published', content_id: 'CONTENT-ID-VAT' },
      { base_path: '/browse/tax/capital-gains', internal_name: 'Tax / Capital Gains Tax', publication_state: 'published', content_id: 'CONTENT-ID-CAPITAL' },
      { base_path: '/browse/tax/rti', internal_name: 'Tax / RTI', publication_state: 'draft', content_id: 'CONTENT-ID-RTI' },
      { base_path: '/browse/tax/nil', internal_name: nil, publication_state: 'draft', content_id: 'CONTENT-ID-NIL' },
    ], document_type: "mainstream_browse_page")

    publishing_api_has_linkables([
      { base_path: '/topic/oil-and-gas/wells', internal_name: 'Oil and Gas / Wells', publication_state: 'published', content_id: 'CONTENT-ID-WELLS' },
      { base_path: '/topic/oil-and-gas/fields', internal_name: 'Oil and Gas / Fields', publication_state: 'published', content_id: 'CONTENT-ID-FIELDS' },
      { base_path: '/topic/oil-and-gas/distillation', internal_name: 'Oil and Gas / Distillation', publication_state: 'draft', content_id: 'CONTENT-ID-DISTILL' },
    ], document_type: "topic")

    publishing_api_has_linkables(
      [
        {
          "public_updated_at" => "2014-10-15 14:35:22",
          "title" => "Student Loans Company",
          "content_id" => "9a9111aa-1db8-4025-8dd2-e08ec3175e72",
          "publication_state" => "live",
          "base_path" => "/government/organisations/student-loans-company",
          "internal_name" => "Student Loans Company"
        },
      ],
      document_type: "organisation")

    publishing_api_has_linkables([
      { internal_name: 'As a user, I need to pay a VAT bill, so that I can pay HMRC what I owe (100550)',
        publication_state: 'published', content_id: 'CONTENT-ID-USER-NEED', },
    ], document_type: 'need')
  end
end
