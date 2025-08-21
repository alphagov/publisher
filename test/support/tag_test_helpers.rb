module TagTestHelpers
  include GdsApi::TestHelpers::PublishingApi

  def stub_linkables
    stub_request(:get, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/expanded-links/.+})
      .to_return(status: 200, body: "{}", headers: {})

    stub_publishing_api_data
  end

  def stub_linkables_with_data
    stub_request(:get, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/expanded-links/.+})
      .to_return(
        status: 200,
        body: "{
          \"expanded_links\":
            {
              \"mainstream_browse_pages\": [
                {
                  \"content_id\": \"CONTENT-ID-CAPITAL\"
                },
                {
                  \"content_id\": \"CONTENT-ID-RTI\"
                },
                {
                  \"content_id\": \"CONTENT-ID-VAT\"
                }
              ],
              \"ordered_related_items\": [
                {
                  \"content_id\": \"830e403b-7d81-45f1-8862-81dcd55b4ec7\",
                  \"base_path\": \"/company-tax-returns\"
                },
                {
                  \"content_id\": \"5cb58486-0b00-4da8-8076-382e474b4f03\",
                  \"base_path\": \"/prepare-file-annual-accounts-for-limited-company\"
                },
                {
                  \"content_id\": \"853feaf2-152c-4aa5-8edb-ba84a88860bf\",
                  \"base_path\": \"/corporation-tax\"
                },
                {
                  \"content_id\": \"91fef6f6-3a59-42ab-a14d-42c4e5eee1a1\",
                  \"base_path\": \"/tax-help\"
                }
              ],
              \"organisations\": [
                {
                  \"content_id\": \"9a9111aa-1db8-4025-8dd2-e08ec3175e72\"
                }
              ],
              \"parent\": [
                {
                  \"content_id\": \"CONTENT-ID-CAPITAL\"
                }
              ]
            },
          \"version\": 1
        }",
        headers: {},
      )

    stub_publishing_api_data
  end

  def stub_linkables_with_single_related_item
    # variation of stub_linkables_with_data only populating one entry for related content
    stub_request(:get, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/expanded-links/.+})
      .to_return(
        status: 200,
        body: "{
          \"expanded_links\":
            {
              \"mainstream_browse_pages\": [],
              \"ordered_related_items\": [
                {
                  \"content_id\": \"830e403b-7d81-45f1-8862-81dcd55b4ec7\",
                  \"base_path\": \"/company-tax-returns\"
                }
              ],
              \"organisations\": [],
              \"parent\": []
            },
          \"version\": 1
        }",
        headers: {},
      )

    stub_publishing_api_data
  end

  def stub_publishing_api_data
    stub_publishing_api_has_linkables(
      [
        { base_path: "/browse/tax/vat", internal_name: "Tax / VAT", publication_state: "published", content_id: "CONTENT-ID-VAT" },
        { base_path: "/browse/tax/capital-gains", internal_name: "Tax / Capital Gains Tax", publication_state: "published", content_id: "CONTENT-ID-CAPITAL" },
        { base_path: "/browse/tax/rti", internal_name: "Tax / RTI", publication_state: "draft", content_id: "CONTENT-ID-RTI" },
        { base_path: "/browse/tax/nil", internal_name: nil, publication_state: "draft", content_id: "CONTENT-ID-NIL" },
        { base_path: "/browse/benefits/families", internal_name: "Benefits / Benefits and financial support for families", publication_state: "draft", content_id: "CONTENT-ID-FAMILIES" },
        { base_path: "/browse/benefits/help-for-carers", internal_name: "Benefits / Benefits and financial support if you're caring for someone", publication_state: "draft", content_id: "CONTENT-ID-HELP-FOR-CARERS" },
        { base_path: "/browse/benefits/disability", internal_name: "Benefits / Benefits and financial support if you're disabled or have a health condition", publication_state: "draft", content_id: "CONTENT-ID-DISABILITY" },
      ],
      document_type: "mainstream_browse_page",
    )

    stub_publishing_api_has_linkables(
      [
        { base_path: "/topic/oil-and-gas/wells", internal_name: "Oil and Gas / Wells", publication_state: "published", content_id: "CONTENT-ID-WELLS" },
        { base_path: "/topic/oil-and-gas/fields", internal_name: "Oil and Gas / Fields", publication_state: "published", content_id: "CONTENT-ID-FIELDS" },
        { base_path: "/topic/oil-and-gas/distillation", internal_name: "Oil and Gas / Distillation", publication_state: "draft", content_id: "CONTENT-ID-DISTILL" },
      ],
      document_type: "topic",
    )

    stub_publishing_api_has_linkables(
      [
        {
          "public_updated_at" => "2014-10-15 14:35:22",
          "title" => "Student Loans Company",
          "content_id" => "9a9111aa-1db8-4025-8dd2-e08ec3175e72",
          "publication_state" => "live",
          "base_path" => "/government/organisations/student-loans-company",
          "internal_name" => "Student Loans Company",
        },
        {
          "public_updated_at" => "2014-10-16 14:35:22",
          "title" => "Department for Education",
          "content_id" => "ebd15ade-73b2-4eaf-b1c3-43034a42eb37",
          "publication_state" => "live",
          "base_path" => "/government/organisations/department-for-education",
          "internal_name" => "Department for Education",
        },
      ],
      document_type: "organisation",
    )

    stub_publishing_api_has_lookups({
      "/company-tax-returns" => "830e403b-7d81-45f1-8862-81dcd55b4ec7",
      "/prepare-file-annual-accounts-for-limited-company" => "5cb58486-0b00-4da8-8076-382e474b4f03",
      "/corporation-tax" => "853feaf2-152c-4aa5-8edb-ba84a88860bf",
      "/tax-help" => "91fef6f6-3a59-42ab-a14d-42c4e5eee1a1",
    })
  end
end
