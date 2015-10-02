# encoding: utf-8
require 'test_helper'

class BusinessSupportExportPresenterTest < ActiveSupport::TestCase
  setup do
    Plek.any_instance.stubs(:website_root).returns("https://www.gov.uk")
  end

  should "provide a CSV export of business support schemes" do
    Area.stubs(:areas_for_edition).returns(
      [
        Area.new(
          id: 1234,
          name: "London",
          codes: {
            "gss" => "E15000007",
          },
        ),
        Area.new(
          id: 2345,
          name: "Hackney Borough Council",
          codes: {
            "gss" => "E09000012",
          },
        ),
        Area.new(
          id: 3456,
          name: "Camden Borough Council",
          codes: {
            "gss" => "E09000007",
          },
        ),
      ]
    )

    BusinessSupport::BusinessSize.stubs(:all).returns([OpenStruct.new(slug: "up-to-249", name: "Up to 249")])
    BusinessSupport::Purpose.stubs(:all).returns(
      ["Business growth and expansion", "Setting up your business", "World Domination"].map { |f| OpenStruct.new(slug: f.parameterize, name: f) })
    BusinessSupport::Sector.stubs(:all).returns([OpenStruct.new(slug: "manufacturing", name: "Manufacturing")])
    BusinessSupport::Stage.stubs(:all).returns(
      ["Start-up", "Grow and sustain"].map { |f| OpenStruct.new(slug: f.parameterize, name: f) })
    BusinessSupport::SupportType.stubs(:all).returns(
      ["Finance", "Loan"].map { |f| OpenStruct.new(slug: f.parameterize, name: f) })

    FactoryGirl.create(:business_support_edition, :slug => "super-finance-triple-bonus", :title => "Super finance triple bonus", :state => "published")
    FactoryGirl.create(:business_support_edition, :slug => "young-business-starter-award", :title => "Young business starter award", :state => "published")
    FactoryGirl.create(:business_support_edition, :slug => "brilliant-start-up-award", :title => "Brilliant start-up award", :state => "published",
                       :organiser => "Capitalise Business Support",
                       :short_description => "Business start-up loans for pre-starts and applicants",
                       :body => "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years. Ask for a quote based on our current rates.",
                       :eligibility => "Typically, we look for the applicant to be contributing at least 25% of the total investment",
                       :evaluation => "Depending on the size of the loan application, you may be asked to meet with one of our business managers",
                       :additional_information => "Business start-up loans from £1,000 to around £10,000 over periods up to 3 years",
                       :contact_details => "Capitalise Business Support\nSummerfields Business Centre\nBohemia Road",
                       :max_employees => 12, :min_value => 1000, :max_value => 10000,
                       :continuation_link => "http://www.capitalise.org/business_start.htm", :will_continue_on => "the Capitalise Business Support website",
                       :areas => ["1234","2345","3456"],
                       :business_sizes => ["up-to-249"],
                       :purposes => ["business-growth-and-expansion", "setting-up-your-business"],
                       :sectors => ["manufacturing"],
                       :stages => ["start-up", "grow-and-sustain"],
                       :support_types => ["finance","loan"],
                       :start_date => 1.year.ago(Date.today),
                       :end_date => 1.year.since(Date.today)
                      )
    FactoryGirl.create(:business_support_edition, :slug => "fooey-award", :title => "Fooey award", :state => "draft")

    csv = BusinessSupportExportPresenter.new(
      BusinessSupportEdition.published.asc("title")).to_csv

    data = CSV.parse(csv, :headers => true)
    assert_equal ["Brilliant start-up award", "Super finance triple bonus", "Young business starter award"], data.map {|r| r["title"] }

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
    assert_equal 1.year.ago(Date.today).to_s, data[0]["start date"]
    assert_equal 1.year.since(Date.today).to_s, data[0]["end date"]
    assert_equal "London, Hackney Borough Council, Camden Borough Council", data[0]["areas"]
    assert_equal "Up to 249", data[0]["business sizes"]
    assert_equal "Business growth and expansion, Setting up your business", data[0]["purposes"]
    assert_equal "Manufacturing", data[0]["sectors"]
    assert_equal "Start-up, Grow and sustain", data[0]["stages"]
    assert_equal "Finance, Loan", data[0]["support types"]
  end
end
