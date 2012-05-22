#encoding: utf-8
require 'integration_test_helper'

class LicenceCreationTest < ActionDispatch::IntegrationTest
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

    fill_in "Licence identifier", :with => "AB1234"
    click_button "Create Licence"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    l = LicenceEdition.first
    assert_equal '2358', l.panopticon_id
    assert_equal 'AB1234', l.licence_identifier
  end
end
