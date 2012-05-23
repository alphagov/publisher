#encoding: utf-8
require 'integration_test_helper'

class LicenceCreateEditTest < ActionDispatch::IntegrationTest
  setup do
    panopticon_has_metadata(
      "id" => 2358,
      "slug" => "foo-bar",
      "kind" => "licence",
      "name" => "Foo bar"
    )

    setup_users
  end

  should "create a new LicenceEdition" do
    visit "/admin/publications/2358"

    assert page.has_content? "We need a bit more information to create your licence."
    assert page.has_content? "Licence identifier can't be blank"

    fill_in "Licence identifier", :with => "AB1234"
    click_button "Create Licence"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    l = LicenceEdition.first
    assert_equal '2358', l.panopticon_id
    assert_equal 'AB1234', l.licence_identifier
  end

  should "allow editing LicenceEdition" do
    licence = FactoryGirl.create(:licence_edition,
                                 :panopticon_id => "2358",
                                 :title => "Foo bar",
                                 :licence_identifier => "ab2345",
                                 :licence_overview => "Licence overview content")

    visit "/admin/editions/#{licence.to_param}"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert page.has_field?("Licence identifier", :with => "ab2345")
    assert page.has_field?("Licence overview", :with => "Licence overview content")

    fill_in "Licence identifier", :with => "5432de"
    fill_in "Licence overview", :with => "New Overview content"

    click_button "Save"

    assert page.has_content? "Licence edition was successfully updated."

    l = LicenceEdition.find(licence.id)
    assert_equal "5432de", l.licence_identifier
    assert_equal "New Overview content", l.licence_overview
  end
end
