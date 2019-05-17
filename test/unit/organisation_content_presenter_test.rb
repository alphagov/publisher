require "test_helper"

class OrganisationContentPresenterTest < ActiveSupport::TestCase
  setup do
    @response = {
            "content_id" => "",
            "expanded_links" => {
              "mainstream_browse_pages" => [
                {
                  "base_path" => "/browse/business/support",
                },
                {
                  "base_path" => "/browse/tax/vat",
                }
              ],
              "organisations" => [
                {
                  "title" => "HMRC"
                }
              ],
              "topics" => [
                {
                  "base_path" => "/topic/business-tax/vat"
                }
              ]
            }
    }
  end

  should "provide a CSV export of content tagged to an organisation" do
    document = FactoryBot.create(:artefact,
                                 name: "Important document",
                                 kind: "answer")

    @response['content_id'] = document.content_id
    publishing_api_has_expanded_links(@response)

    FactoryBot.create(:edition,
                      panopticon_id: document.id)

    csv = OrganisationContentPresenter.new(
      Artefact.where(owning_app: "publisher").not_in(state: %w[archived])
    ).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal "Important document", data[0]["Name"]
    assert_equal "answer", data[0]["Format"]
    assert_equal "HMRC", data[0]["Organisations"]
    assert_equal "business-tax/vat", data[0]["Topics"]
    assert_equal "business/support,tax/vat", data[0]["Browse pages"]
  end

  should "handle artefacts without editions" do
    FactoryBot.create(:artefact,
                      name: "Important document")

    csv = OrganisationContentPresenter.new(
      Artefact.where(owning_app: "publisher").not_in(state: %w[archived])
    ).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal "Important document", data[0]["Name"]
  end
end
