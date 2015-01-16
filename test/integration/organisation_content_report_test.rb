# encoding: utf-8
require_relative '../integration_test_helper'

class OrganisationContentReportTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  setup do
    setup_users
  end

  should "provide a CSV export of business support schemes" do
    document = FactoryGirl.create(:artefact,
      name: "Important document",
      department: "HMRC",
      need_ids: ["123456","123321","654321"]
    )
    FactoryGirl.create(:edition,
      browse_pages: ["business/support", "tax/vat"],
      primary_topic: "business-tax/vat",
      additional_topics: ["oil-and-gas/licensing", "environmental-management/boating"],
      panopticon_id: document.id
    )

    get "/reports/organisation-content"

    assert last_response.ok?
    assert_equal 'text/csv', last_response.headers['Content-Type']
    assert_equal %{attachment; filename=organisation_content-#{Date.today.strftime("%F")}.csv}, last_response.headers['Content-Disposition']

    data = CSV.parse(last_response.body, :headers => true)

    assert_equal "Important document", data[0]["Name"]
    assert_equal "business/support,tax/vat", data[0]["Browse pages"]
    assert_equal "business-tax/vat", data[0]["Primary topic"]
    assert_equal "oil-and-gas/licensing,environmental-management/boating", data[0]["Additional topics"]
    assert_equal "HMRC", data[0]["Organisation"]
    assert_equal "123456,123321,654321", data[0]["Need ids"]
  end
end
