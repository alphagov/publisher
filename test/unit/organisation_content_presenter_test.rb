# encoding: utf-8
require "test_helper"

class OrganisationContentPresenterTest < ActiveSupport::TestCase
  should "provide a CSV export of business support schemes" do
    hmrc = FactoryGirl.create(:live_tag,
                               tag_id: "hm-revenue-customs",
                               title: "HMRC",
                               tag_type: "organisation")

    document = FactoryGirl.create(:artefact,
      name: "Important document",
      organisations: [hmrc.tag_id],
      need_ids: ["123456","123321","654321"]
    )
    FactoryGirl.create(:edition,
      browse_pages: ["business/support", "tax/vat"],
      primary_topic: "business-tax/vat",
      additional_topics: ["oil-and-gas/licensing", "environmental-management/boating"],
      panopticon_id: document.id
    )

    csv = OrganisationContentPresenter.new(
            Artefact.where(owning_app: "publisher").not_in(state: ["archived"]))
            .to_csv
    data = CSV.parse(csv, :headers => true)

    assert_equal "Important document", data[0]["Name"]
    assert_equal "business/support,tax/vat", data[0]["Browse pages"]
    assert_equal "business-tax/vat", data[0]["Primary topic"]
    assert_equal "oil-and-gas/licensing,environmental-management/boating", data[0]["Additional topics"]
    assert_equal "HMRC", data[0]["Organisations"]
    assert_equal "123456,123321,654321", data[0]["Need ids"]
  end

  should "handle artefacts without editions" do
    document = FactoryGirl.create(:artefact,
      name: "Important document",
      need_ids: ["123456"]
    )

    csv = OrganisationContentPresenter.new(
            Artefact.where(owning_app: "publisher").not_in(state: ["archived"]))
            .to_csv
    data = CSV.parse(csv, :headers => true)

    assert_equal "Important document", data[0]["Name"]
  end
end
