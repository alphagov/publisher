require 'test_helper'
require 'gds_api/test_helpers/imminence'
require 'imminence_areas_test_helper'

class AreaTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::Imminence
  include ImminenceAreasTestHelper

  setup do
    stub_mapit_areas_requests(IMMINENCE_API_ENDPOINT)
  end

  def test_api_data_memoization
    Area.class_eval('@areas = nil') # rubocop:disable Style/EvalWithLocation

    3.times { Area.all }

    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/EUR.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/CTY.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/DIS.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/LBO.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/LGD.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/MTD.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/UTA.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/COI.json}, times: 1
  end

  def test_area_types
    assert_equal %w(EUR CTY DIS LBO LGD MTD UTA COI), Area::AREA_TYPES
  end

  context ".all" do
    should "return areas of all types" do
      all_areas = regions_with_gss_codes +
        counties +
        districts +
        london_boroughs +
        ni_councils +
        metropolitan_councils +
        unitary_authorities +
        isles_of_scilly

      assert_equal(all_areas, Area.all.map(&:marshal_dump))
    end

    should "exclude areas without GSS codes" do
      assert Area.all.map(&:marshal_dump).exclude?(region_without_gss_code)
    end
  end

  context ".areas_for_edition" do
    should "return correct Areas" do
      edition = OpenStruct.new(
        area_gss_codes: %w(E15000007 E09000012),
      )

      assert_equal ["London", "Hackney Borough Council"],
                   Area.areas_for_edition(edition).map(&:name)
    end

    should "not return duplicate Areas" do
      edition = OpenStruct.new(
        area_gss_codes: %w(E15000007 E09000012 E15000007),
      )

      assert_equal ["London", "Hackney Borough Council"],
                   Area.areas_for_edition(edition).map(&:name)
    end
  end

  def test_regions
    assert_equal %w(London Scotland), Area.regions.map(&:name)
  end

  def test_english_regions
    assert_equal %w[London], Area.english_regions.map(&:name)
  end
end
