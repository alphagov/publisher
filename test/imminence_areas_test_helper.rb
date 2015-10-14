module ImminenceAreasTestHelper

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

  def regions
    [
      {
        slug: "london",
        name: "London",
        type: "EUR",
        country_name: "England",
        codes: {
          "gss" => "E15000007",
        },
      },
      {
        slug: "scotland",
        name: "Scotland",
        type: "EUR",
        country_name: "Scotland",
        codes: {
          "gss" => "S15000001",
        },
      },
    ]
  end

  def counties
    [
      {
        slug: "west-sussex-county-council",
        name: "West Sussex County Council",
        type: "CTY",
        codes: {
          "gss" => "E10000032",
        },
      },
      {
        slug: "devon-county-council",
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
        slug: "wycombe-district-council",
        name: "Wycombe District Council",
        type: "DIS",
        codes: {
          "gss" => "E07000007",
        },
      },
      {
        slug: "south-bucks-district-council",
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
        slug: "hackney-borough-council",
        name: "Hackney Borough Council",
        type: "LBO",
        codes: {
          "gss" => "E09000012",
        },
      },
      {
        slug: "camden-borough-council",
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
        slug: "derry-city-council",
        name: "Derry City Council",
        type: "LGD",
        codes: {
          "gss" => "N09000005",
        },
      },
      {
        slug: "belfast-city-council",
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
        slug: "birmingham-city-council",
        name: "Birmingham City Council",
        type: "MTD",
        codes: {
          "gss" => "E08000025",
        },
      },
      {
        slug: "leeds-city-council",
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
        slug: "glasgow-city-council",
        name: "Glasgow City Council",
        type: "UTA",
        codes: {
          "gss" => "S12000046",
        },
      },
      {
        slug: "cardiff-council",
        name: "Cardiff Council",
        type: "UTA",
        codes: {
          "gss" => "W06000015",
        },
      },
    ]
  end

  def stub_mapit_areas_requests(endpoint)

    stub_request(:get, %r{\A#{endpoint}/areas/EUR.json}).to_return(
      body: areas_response(regions)
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
  end
end
