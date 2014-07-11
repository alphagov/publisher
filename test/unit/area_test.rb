require 'test_helper'
require 'gds_api/test_helpers/imminence'

class AreaTest < ActiveSupport::TestCase

  include GdsApi::TestHelpers::Imminence

  def areas_response(areas)
    {
      "_response_info" => { "status" => "ok","links" => [] },
      "total" => areas.size,
      "start_index" => 1,
      "page_size" => areas.size,
      "current_page" => 1,
      "pages" => 1,
      "results" => areas
    }.to_json
  end

  def setup
    @regions = [{slug: "london", name: "London", type: "EUR", country_name: "England"},
                {slug: "scotland", name: "Scotland", type: "EUR", country_name: "Scotland"}]

    @counties = [{slug: "west-sussex-county-council", name: "West Sussex County Council", type: "CTY"},
                 {slug: "devon-county-council", name: "Devon County Council", type: "CTY"}]

    @districts = [{slug: "wycombe-district-council", name: "Wycombe District Council", type: "DIS"},
                  {slug: "south-bucks-district-council", name: "South Bucks District Council", type: "DIS"}]

    @london_boroughs = [{slug: "hackney-borough-council", name: "Hackney Borough Council", type: "LBO"},
                        {slug: "camden-borough-council", name: "Camden Borough Council", type: "LBO"}]

    stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/EUR.json}).to_return(
      body: areas_response(@regions)
    )
    stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/CTY.json}).to_return(
      body: areas_response(@counties)
    )
    stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/DIS.json}).to_return(
      body: areas_response(@districts)
    )
    stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/LBO.json}).to_return(
      body: areas_response(@london_boroughs)
    )
  end

  def test_api_data_memoization
    Area.class_eval('@areas = nil')

    3.times { Area.all }

    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/EUR.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/CTY.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/DIS.json}, times: 1
    assert_requested :get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/LBO.json}, times: 1
  end

  def test_area_types
    assert_equal ['EUR','CTY','DIS','LBO'], Area::AREA_TYPES
  end

  def test_all
    assert_equal @regions + @counties + @districts + @london_boroughs, Area.all.map(&:marshal_dump)
  end

  def test_areas_for_edition
    edition = OpenStruct.new(areas: ["london", "hackney-borough-council"])
    assert_equal ["London", "Hackney Borough Council"], Area.areas_for_edition(edition).map(&:name)
  end

  def test_regions
    assert_equal ["London", "Scotland"], Area.regions.map(&:name)
  end

  def test_english_regions
    assert_equal ["London"], Area.english_regions.map(&:name)
  end
end
