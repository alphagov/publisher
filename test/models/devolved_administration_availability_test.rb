require "test_helper"

class DevolvedAdministrationAvailabilityTest < ActiveSupport::TestCase
  test "should not be valid with an unallowed type value" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
      type: "invalid_type",
    )
    assert_not devolved_administration_availability.valid?
  end

  test "should be valid with an allowed type value" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
    )
    assert devolved_administration_availability.valid?
  end

  test "should not be valid if alternative_url is not present when devolved_administration_service is selected" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
      type: "devolved_administration_service",
      alternative_url: "",
    )
    assert_not devolved_administration_availability.valid?
  end

  test "should be valid if alternative_url is present when devolved_administration_service is selected" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
      type: "devolved_administration_service",
      alternative_url: "https://www.scot.gov/service",
    )
    assert devolved_administration_availability.valid?
  end

  test "should not be valid if alternative_url is not a valid URI" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
      type: "devolved_administration_service",
      alternative_url: "abc",
    )
    assert_not devolved_administration_availability.valid?
  end

  test "should be valid if alternative_url is a valid URI" do
    devolved_administration_availability = FactoryBot.build(
      :devolved_administration_availability,
      type: "devolved_administration_service",
      alternative_url: "https://www.scot.gov/service",
    )
    assert devolved_administration_availability.valid?
  end
end
