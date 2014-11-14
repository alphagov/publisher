#encoding: utf-8
require 'integration_test_helper'

class LicenceCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "licence",
        name: "Foo bar",
        owning_app: "publisher",
    )

    setup_users
    stub_collections
  end

  should "create a new LicenceEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content? "We need a bit more information to create your licence."
    assert page.has_content? "Licence identifier can't be blank"

    fill_in "Licence identifier", :with => "AB1234"
    click_button "Create Licence"

    assert page.has_content? "Foo bar Edition 1"

    l = LicenceEdition.first
    assert_equal @artefact.id.to_s, l.panopticon_id
    assert_equal 'AB1234', l.licence_identifier
  end

  should "allow editing LicenceEdition" do
    licence = FactoryGirl.create(:licence_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Foo bar",
                                 :licence_identifier => "ab2345",
                                 :licence_short_description => "Short description content",
                                 :licence_overview => "Licence overview content",
                                 :will_continue_on => "The HMRC website",
                                 :continuation_link => "http://www.hmrc.gov.uk")

    visit "/editions/#{licence.to_param}"

    assert page.has_content? "Foo bar Edition 1"

    assert page.has_field?("Licence identifier", :with => "ab2345")
    assert page.has_field?("Licence short description", :with => "Short description content")
    assert page.has_field?("Licence overview", :with => "Licence overview content")
    assert page.has_field?("Will continue on", :with => "The HMRC website")
    assert page.has_field?("Link to competent authority", :with => "http://www.hmrc.gov.uk")

    fill_in "Licence identifier", :with => "5432de"
    fill_in "Licence short description", :with => "New short description"
    fill_in "Licence overview", :with => "New Overview content"
    fill_in "Will continue on", :with => "The DVLA website"
    fill_in "Link to competent authority", :with => "http://www.dvla.gov.uk"

    save_edition

    assert page.has_content? "Licence edition was successfully updated."

    l = LicenceEdition.find(licence.id)
    assert_equal "5432de", l.licence_identifier
    assert_equal "New short description", l.licence_short_description
    assert_equal "New Overview content", l.licence_overview
  end

  should "allow creating a new version of a LicenceEdition" do
    licence = FactoryGirl.create(:licence_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :licence_identifier => "ab2345",
                                 :licence_short_description => "Short description content",
                                 :licence_overview => "Licence overview content",
                                 :will_continue_on => "The HMRC website",
                                 :continuation_link => "http://www.hmrc.gov.uk")

    visit "/editions/#{licence.to_param}"
    click_on "Create new edition"

    assert page.has_content? "Foo bar Edition 2"

    assert page.has_field?("Licence identifier", :with => "ab2345")
    assert page.has_field?("Licence short description", :with => "Short description content")
    assert page.has_field?("Licence overview", :with => "Licence overview content")
    assert page.has_field?("Will continue on", :with => "The HMRC website")
    assert page.has_field?("Link to competent authority", :with => "http://www.hmrc.gov.uk")
  end
end
