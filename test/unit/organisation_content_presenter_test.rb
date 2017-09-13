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
              "meets_user_needs" => [
                {
                  "details" =>
                  {
                    "need_id" => '123456'
                  }
                },
                {
                  "details" =>
                  {
                    "need_id" => '123321'
                  }
                },
                {
                  "details" =>
                  {
                    "need_id" => '654321'
                  }
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

  should "provide a CSV export of business support schemes" do
    document = FactoryGirl.create(:artefact,
                                  name: "Important document",
                                  kind: "answer")

    @response['content_id'] = document.content_id
    publishing_api_has_expanded_links(@response)

    FactoryGirl.create(:edition,
                       panopticon_id: document.id)

    csv = OrganisationContentPresenter.new(
      Artefact.where(owning_app: "publisher").not_in(state: ["archived"])
    ).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal "Important document", data[0]["Name"]
    assert_equal "answer", data[0]["Format"]
    assert_equal "123456,123321,654321", data[0]["Need ids"]
    assert_equal "HMRC", data[0]["Organisations"]
    assert_equal "business-tax/vat", data[0]["Topics"]
    assert_equal "business/support,tax/vat", data[0]["Browse pages"]
  end

  should "handle artefacts without editions" do
    FactoryGirl.create(:artefact,
                       name: "Important document",
                       need_ids: ["123456"])

    csv = OrganisationContentPresenter.new(
      Artefact.where(owning_app: "publisher").not_in(state: ["archived"])
    ).to_csv
    data = CSV.parse(csv, headers: true)

    assert_equal "Important document", data[0]["Name"]
  end
end
