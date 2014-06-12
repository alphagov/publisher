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

    BusinessSupport::BusinessSize.collection.insert([
      {slug: 'under-10', name: 'Under 10'},
      {slug: 'up-to-249', name: 'Up to 249'},
      {slug: 'over-1000000', name: 'Over 1 million'}
    ])

    BusinessSupport::BusinessType.collection.insert([
      {slug:'charity', name:'Charity'},
      {slug:'limited-company',name:'Limited company'},
      {slug:'plc',name:'Public limited company'}
    ])

    BusinessSupport::Purpose.collection.insert([
      {slug:'expansion', name: 'Expansion'},
      {slug:'world-domination', name: 'World domination'}
    ])

    BusinessSupport::Sector.collection.insert([
      {slug:'manufacturing', name: 'Manufacturing'},
      {slug:'education', name: 'Education'}
    ])

    BusinessSupport::Stage.collection.insert([
      {slug:'start-up', name:'Start-up'},
      {slug:'grow-and-sustain', name:'Grow and sustain'}
    ])

    BusinessSupport::SupportType.collection.insert([
      {slug:'grant', name:'Grant'}, {slug:'loan', name:'Loan'}
    ])

    setup_users
  end

  should "create a new BusinessSupportEdition" do
    visit "/publications/#{@artefact.id}"

    assert_match /^\/editions\/[0-9a-z]+?$/, current_path
    assert page.has_content? "Viewing “Foo bar” Edition 1"

    bs = BusinessSupportEdition.first
    assert_equal @artefact.id.to_s, bs.panopticon_id
  end

  should "allow editing BusinessSupportEdition" do
    a_year_ago = 1.year.ago(Date.today)
    a_year_since = 1.year.since(Date.today)

    bs = FactoryGirl.create(:business_support_edition,
                           :panopticon_id => @artefact.id,
                           :title => "Foo bar",
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
                           :continuation_link => "http://www.hmrc.gov.uk",
                           :priority => 2,
                           :start_date => a_year_ago,
                           :end_date => a_year_since,
                           :business_sizes => ["up-to-249"],
                           :business_types => ["charity"],
                           :purposes => ["world-domination"],
                           :sectors => ["education"],
                           :stages => ["grow-and-sustain"],
                           :support_types => ["grant", "loan"])

    visit "/editions/#{bs.to_param}"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

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
    assert page.has_select?("edition_priority", :selected => "High")
    assert page.has_select?("edition_start_date_1i", :selected => a_year_ago.year.to_s)
    assert page.has_select?("edition_start_date_2i", :selected => a_year_ago.strftime("%B"))
    assert page.has_select?("edition_start_date_3i", :selected => a_year_ago.day.to_s)
    assert page.has_select?("edition_end_date_1i", :selected => a_year_since.year.to_s)
    assert page.has_select?("edition_end_date_2i", :selected => a_year_since.strftime("%B"))
    assert page.has_select?("edition_end_date_3i", :selected => a_year_since.day.to_s)

    assert page.has_checked_field?("edition_business_sizes_up-to-249")
    assert page.has_checked_field?("edition_business_types_charity")
    assert page.has_checked_field?("edition_purposes_world-domination")
    assert page.has_checked_field?("edition_sectors_education")
    assert page.has_checked_field?("edition_stages_grow-and-sustain")
    assert page.has_checked_field?("edition_support_types_grant")
    assert page.has_checked_field?("edition_support_types_loan")

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

    select "Normal", :from => "edition_priority"
    select Date.today.year.to_s, :from => "edition_start_date_1i"

    # circumvent poltergeist not handling bootstrap modals
    # by directly triggering our expected change
    find('#edition_sectors_manufacturing').trigger('click')
    uncheck "edition_support_types_loan"

    click_button "Save"

    assert page.has_content? "Business support edition was successfully updated."

    bs.reload

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
    assert_equal 1, bs.priority
    assert page.has_select?("edition_priority", :selected => "Normal")
    assert_equal Date.today, bs.start_date
    assert page.has_select?("edition_start_date_1i", :selected => Date.today.year.to_s)
    assert page.has_select?("edition_start_date_2i", :selected => Date.today.strftime("%B"))
    assert page.has_select?("edition_start_date_3i", :selected => Date.today.day.to_s)
    assert page.has_checked_field?("edition_sectors_manufacturing")
    refute page.has_checked_field?("edition_support_type_loan")
  end

  should "allow creating a new version of a BusinessSupportEdition" do
    business_support = FactoryGirl.create(:business_support_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :short_description => "Super business support",
                                 :body => "This is the super business support scheme")

    visit "/editions/#{business_support.to_param}"

    click_on "Create new edition"

    assert page.has_content? "Viewing “Foo bar” Edition 2"

  end

  should "not allow entering non-numeric values into numeric fields" do
    business_support = FactoryGirl.create(:business_support_edition,
                                 :panopticon_id => @artefact.id)

    visit "/editions/#{business_support.to_param}"

    fill_in "Min value", :with => "1,500"
    fill_in "Max value", :with => "£10,000"
    fill_in "Max employees", :with => "1,000"

    click_button "Save"

    assert page.has_content?("We had some problems saving")

    within '#edition_min_value_input' do
      assert page.has_content?("is not a number")
    end
    within '#edition_max_value_input' do
      assert page.has_content?("is not a number")
    end
    within '#edition_max_employees_input' do
      assert page.has_content?("is not a number")
    end
  end

  should "disable fields for a published edition" do
    business_support = FactoryGirl.create(:business_support_edition,
                                          :panopticon_id => @artefact.id,
                                          :state => 'published')

    visit "/admin/editions/#{business_support.to_param}"

    assert page.has_css?("input#edition_title[disabled]")
    assert page.has_css?("input#edition_organiser[disabled]")
    assert page.has_css?("textarea#edition_eligibility[disabled]")
    assert page.has_css?("textarea#edition_evaluation[disabled]")
    assert page.has_css?("textarea#edition_contact_details[disabled]")
    assert page.has_css?("input#edition_max_employees[disabled]")
    assert page.has_css?("input#edition_min_value[disabled]")
    assert page.has_css?("input#edition_max_value[disabled]")
    assert page.has_css?("input#edition_will_continue_on[disabled]")
    assert page.has_css?("input#edition_continuation_link[disabled]")
    assert page.has_css?("select#edition_priority[disabled]")
    assert page.has_css?("select#edition_start_date_1i[disabled]")
    assert page.has_css?("select#edition_start_date_2i[disabled]")
    assert page.has_css?("select#edition_start_date_3i[disabled]")
    assert page.has_css?("select#edition_end_date_1i[disabled]")
    assert page.has_css?("select#edition_end_date_2i[disabled]")
    assert page.has_css?("select#edition_end_date_3i[disabled]")

    assert page.has_css?("input#business_support_business_type_check_all[disabled]")
    assert page.has_css?("input#edition_business_types_charity[disabled]")
    assert page.has_css?("input#edition_business_types_limited-company[disabled]")
    assert page.has_css?("input#edition_business_types_plc[disabled]")

    assert page.has_css?("input#business_support_business_size_check_all[disabled]")
    assert page.has_css?("input#edition_business_sizes_under-10[disabled]")
    assert page.has_css?("input#edition_business_sizes_up-to-249[disabled]")
    assert page.has_css?("input#edition_business_sizes_over-1000000[disabled]")

    assert page.has_css?("input#business_support_purpose_check_all[disabled]")
    assert page.has_css?("input#edition_purposes_expansion[disabled]")
    assert page.has_css?("input#edition_purposes_world-domination[disabled]")

    assert page.has_css?("input#business_support_sector_check_all[disabled]")
    assert page.has_css?("input#edition_sectors_education[disabled]")
    assert page.has_css?("input#edition_sectors_manufacturing[disabled]")

    assert page.has_css?("input#business_support_stage_check_all[disabled]")
    assert page.has_css?("input#edition_stages_start-up[disabled]")
    assert page.has_css?("input#edition_stages_grow-and-sustain[disabled]")

    assert page.has_css?("input#business_support_support_type_check_all[disabled]")
    assert page.has_css?("input#edition_support_types_grant[disabled]")
    assert page.has_css?("input#edition_support_types_loan[disabled]")
  end
end
