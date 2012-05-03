require 'test_helper'
require_relative 'helpers/local_services_helper'


class LocalAuthorityTest < ActiveSupport::TestCase
  def setup
    LocalAuthority.delete_all
  end

  should 'create an authority with correct field types' do
    # Although it may seem overboard, this test is helpful to confirm
    # the correct field types are being used on the model
    LocalAuthority.create!(
                  name: "Example",
                  snac: "AA00",
                  local_directgov_id: 1,
                  tier: "county",
                  contact_address: ["Line one", "line two", "line three"],
                  contact_url: "http://example.gov/contact",
                  contact_phone: "0000000000",
                  contact_email: "contact@example.gov")
    authority = LocalAuthority.first
    assert_equal "Example", authority.name
    assert_equal "AA00", authority.snac
    assert_equal 1, authority.local_directgov_id
    assert_equal "county", authority.tier
    assert_equal ["Line one", "line two", "line three"], authority.contact_address
    assert_equal "http://example.gov/contact", authority.contact_url
    assert_equal "0000000000", authority.contact_phone
    assert_equal "contact@example.gov", authority.contact_email
  end
end