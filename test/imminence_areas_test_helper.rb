module ImminenceAreasTestHelper
  def areas_response(areas)
    {
      "_response_info" => { "status" => "ok", "links" => [] },
      "total" => areas.size,
      "start_index" => 1,
      "page_size" => areas.size,
      "current_page" => 1,
      "pages" => 1,
      "results" => areas
    }.to_json
  end

  def regions_with_gss_codes
    [
      {
        name: "London",
        type: "EUR",
        country_name: "England",
        codes: {
          "gss" => "E15000007",
        },
      },
      {
        name: "Scotland",
        type: "EUR",
        country_name: "Scotland",
        codes: {
          "gss" => "S15000001",
        },
      },
    ]
  end

  def region_without_gss_code
    {
      name: "England",
      type: "EUR",
      country_name: "England",
      codes: {
        "gss" => nil,
      }
    }
  end

  def counties
    [
      {
        name: "West Sussex County Council",
        type: "CTY",
        codes: {
          "gss" => "E10000032",
        },
      },
      {
        name: "Devon County Council",
        type: "CTY",
        codes: {
          "gss" => "E10000008",
        },
      },
    ]
  end

  def districts
    [
      {
        name: "Wycombe District Council",
        type: "DIS",
        codes: {
          "gss" => "E07000007",
        },
      },
      {
        name: "South Bucks District Council",
        type: "DIS",
        codes: {
          "gss" => "E07000006",
        },
      },
    ]
  end

  def london_boroughs
    [
      {
        name: "Hackney Borough Council",
        type: "LBO",
        codes: {
          "gss" => "E09000012",
        },
      },
      {
        name: "Camden Borough Council",
        type: "LBO",
        codes: {
          "gss" => "E09000007",
        },
      },
    ]
  end

  def ni_councils
    [
      {
        name: "Derry City Council",
        type: "LGD",
        codes: {
          "gss" => "N09000005",
        },
      },
      {
        name: "Belfast City Council",
        type: "LGD",
        codes: {
          "gss" => "N09000003",
        },
      },
    ]
  end

  def metropolitan_councils
    [
      {
        name: "Birmingham City Council",
        type: "MTD",
        codes: {
          "gss" => "E08000025",
        },
      },
      {
        name: "Leeds City Council",
        type: "MTD",
        codes: {
          "gss" => "E08000035",
        },
      },
    ]
  end

  def unitary_authorities
    [
      {
        name: "Glasgow City Council",
        type: "UTA",
        codes: {
          "gss" => "S12000046",
        },
      },
      {
        name: "Cardiff Council",
        type: "UTA",
        codes: {
          "gss" => "W06000015",
        },
      },
    ]
  end

  def isles_of_scilly
    [
      {
        name: "Isles of Scilly",
        type: "COI",
        codes: {
          "gss" => "E06000053",
        },
      },
    ]
  end

  def stub_mapit_areas_requests(endpoint)
    stub_request(:get, %r{\A#{endpoint}/areas/EUR.json}).to_return(
      body: areas_response(regions_with_gss_codes.unshift(region_without_gss_code))
    )
    stub_request(:get, %r{\A#{endpoint}/areas/CTY.json}).to_return(
      body: areas_response(counties)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/DIS.json}).to_return(
      body: areas_response(districts)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/LBO.json}).to_return(
      body: areas_response(london_boroughs)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/LGD.json}).to_return(
      body: areas_response(ni_councils)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/MTD.json}).to_return(
      body: areas_response(metropolitan_councils)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/UTA.json}).to_return(
      body: areas_response(unitary_authorities)
    )
    stub_request(:get, %r{\A#{endpoint}/areas/COI.json}).to_return(
      body: areas_response(isles_of_scilly)
    )
  end
end
