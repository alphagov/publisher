#encoding: utf-8
require 'integration_test_helper'

class BusinessSupportCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "business_support",
        name: "Foo bar",
        owning_app: "publisher",
    )

    setup_users
  end

  should "create a new BusinessSupportEdition" do
    visit "/admin/publications/#{@artefact.id}"
    
    assert page.has_content? "We need a bit more information to create your business support."
    assert page.has_content? "Business support identifier can't be blank"

    fill_in "Business support identifier", :with => "AB1234"
    click_button "Create Business support edition"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    bs = BusinessSupportEdition.first
    assert_equal @artefact.id.to_s, bs.panopticon_id
    assert_equal 'AB1234', bs.business_support_identifier
  end

  should "allow editing BusinessSupportEdition" do
    business_support = FactoryGirl.create(:business_support_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Foo bar",
                                 :business_support_identifier => "ab2345",
                                 :organiser => "Business support corp.",
                                 :short_description => "Short description content",
                                 :body => "Body content",
                                 :additional_information => "More information here",
                                 :min_value => 5000,
                                 :max_value => 20000,
                                 :max_employees => 250,
                                 :eligibility => "Small to medium business",
                                 :evaluation => "Evaluate! Evaluate!",
                                 :contact_details => "The business support people.",
                                 :will_continue_on => "The HMRC website",
                                 :continuation_link => "http://www.hmrc.gov.uk")
    visit "/admin/editions/#{business_support.to_param}"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert page.has_field?("Business support identifier", :with => "ab2345")
    assert page.has_field?("Organiser", :with => "Business support corp.")
    assert page.has_field?("Short description", :with => "Short description content")
    assert page.has_field?("Body", :with => "Body content")
    assert page.has_field?("Additional information", :with => "More information here")
    assert page.has_field?("Min value", :with => "5000")
    assert page.has_field?("Max value", :with => "20000")
    assert page.has_field?("Max employees", :with => "250")
    assert page.has_field?("Eligibility", :with => "Small to medium business")
    assert page.has_field?("Evaluation", :with => "Evaluate! Evaluate!")
    assert page.has_field?("Contact details", :with => "The business support people.")
    assert page.has_field?("Will continue on", :with => "The HMRC website")
    assert page.has_field?("Continuation link", :with => "http://www.hmrc.gov.uk")


    fill_in "Business support identifier", :with => "5432de"
    fill_in "Organiser", :with => "Business support inc."
    fill_in "Short description", :with => "New short description"
    fill_in "Body", :with => "This body has changed"
    fill_in "Additional information", :with => "Even more information here."
    fill_in "Min value", :with => 1000
    fill_in "Max value", :with => 10000
    fill_in "Max employees", :with => 500
    fill_in "Eligibility", :with => "Small and medium businesses"
    fill_in "Evaluation", :with => "1 month evaluation period"
    fill_in "Contact details", :with => "Business support corp."
    fill_in "Will continue on", :with => "The business support corp. website"
    fill_in "Continuation link", :with => "http://www.business-support.com"

    click_button "Save"

    assert page.has_content? "Business support edition was successfully updated."

    bs = BusinessSupportEdition.find(business_support.id)
    assert_equal "5432de", bs.business_support_identifier
    assert_equal "Business support inc.", bs.organiser
    assert_equal "New short description", bs.short_description
    assert_equal "This body has changed", bs.body
    assert_equal "Even more information here.", bs.additional_information
    assert_equal 1000, bs.min_value
    assert_equal 10000, bs.max_value
    assert_equal 500, bs.max_employees
    assert_equal "Small and medium businesses", bs.eligibility
    assert_equal "1 month evaluation period", bs.evaluation
    assert_equal "Business support corp.", bs.contact_details
    assert_equal "The business support corp. website", bs.will_continue_on
    assert_equal "http://www.business-support.com", bs.continuation_link
  end

  should "allow creating a new version of a BusinessSupportEdition" do
    business_support = FactoryGirl.create(:business_support_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :business_support_identifier => "ab2345",
                                 :short_description => "Super business support",
                                 :body => "This is the super business support scheme")
    
    visit "/admin/editions/#{business_support.to_param}"
    
    click_on "Create new edition"

    assert page.has_content? "Viewing “Foo bar” Edition 2"

    assert page.has_field?("Business support identifier", :with => "ab2345")
  end
end
