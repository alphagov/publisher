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
    @regions = [{id: 9728, name: "London", type: "EUR", country_name: "England"},
                {id: 9730, name: "Scotland", type: "EUR", country_name: "Scotland"}]
    @counties = [{id: 1764, name: "West Sussex County Council", type: "CTY"},
                {id: 1767, name: "Devon County Council", type: "CTY"}]
    @districts = [{id: 1768, name: "Wycombe District Council", type: "DIS"},
                 {id: 1769, name: "South Bucks District Council", type: "DIS"}]
    @london_boroughs = [{id: 1994, name: "Hackney Borough Council", type: "LBO"},
                      {id: 1991, name: "Camden Borough Council", type: "LBO"}]

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
    edition = OpenStruct.new(areas: ["9728", "1994"])
    assert_equal ["London", "Hackney Borough Council"], Area.areas_for_edition(edition).map(&:name)
  end

  def test_regions
    assert_equal ["London", "Scotland"], Area.regions.map(&:name)
  end

  def test_english_regions
    assert_equal ["London"], Area.english_regions.map(&:name)
  end
end
