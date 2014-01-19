# encoding: utf-8
require_relative '../integration_test_helper'

class BusinessSupportCSVExportTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  setup do
    Plek.any_instance.stubs(:website_root).returns("https://www.gov.uk")
  end

  should "provide a CSV export of business support schemes" do
    FactoryGirl.create(:business_support_edition, :slug => "super-finance-triple-bonus", :title => "Super finance triple bonus", :state => "published",
                       :business_support_identifier => "1")
    FactoryGirl.create(:business_support_edition, :slug => "young-business-starter-award", :title => "Young business starter award", :state => "published",
                       :business_support_identifier => "2")
    FactoryGirl.create(:business_support_edition, :slug => "brilliant-start-up-award", :title => "Brilliant start-up award", :state => "published",
                       :business_support_identifier => "3", :organiser => "Capitalise Business Support",
                       :short_description => "Business start-up loans for pre-starts and applicants",
                       :body => "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years. Ask for a quote based on our current rates.",
                       :eligibility => "Typically, we look for the applicant to be contributing at least 25% of the total investment",
                       :evaluation => "Depending on the size of the loan application, you may be asked to meet with one of our business managers",
                       :additional_information => "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years",
                       :contact_details => "Capitalise Business Support\nSummerfields Business Centre\nBohemia Road",
                       :max_employees => 12, :min_value => 1000, :max_value => 10000,
                       :continuation_link => "http://www.capitalise.org/business_start.htm", :will_continue_on => "the Capitalise Business Support website"
                      )
    FactoryGirl.create(:business_support_edition, :slug => "fooey-award", :title => "Fooey award", :state => "draft")

    get "/reports/business_support_schemes_content.csv"

    assert last_response.ok?
    assert_equal 'text/csv', last_response.headers['Content-Type']
    assert_equal 'attachment; filename="business_support_schemes_content.csv"', last_response.headers['Content-Disposition']

    data = CSV.parse(last_response.body, :headers => true)
    assert_equal ["Brilliant start-up award", "Super finance triple bonus", "Young business starter award"], data.map {|r| r["title"] }
    assert_equal %w(3 1 2), data.map {|r| r["id"]}

    assert_equal "https://www.gov.uk/brilliant-start-up-award", data[0]["web URL"]
    assert_equal "Capitalise Business Support", data[0]["organiser"]
    assert_equal "Business start-up loans for pre-starts and applicants", data[0]["short description"]
    assert_equal "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years. Ask for a quote based on our current rates.", data[0]["body"]
    assert_equal "Typically, we look for the applicant to be contributing at least 25% of the total investment", data[0]["eligibility"]
    assert_equal "Depending on the size of the loan application, you may be asked to meet with one of our business managers", data[0]["evaluation"]
    assert_equal "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years", data[0]["additional information"]
    assert_equal "Capitalise Business Support\nSummerfields Business Centre\nBohemia Road", data[0]["contact details"]
    assert_equal "12", data[0]["max employees"]
    assert_equal "1000", data[0]["min value"]
    assert_equal "10000", data[0]["max value"]
    assert_equal "http://www.capitalise.org/business_start.htm", data[0]["continuation link"]
    assert_equal "the Capitalise Business Support website", data[0]["will continue on"]
  end
end
