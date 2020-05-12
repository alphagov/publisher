module AreasHelper
  def edition_areas_select_options(edition)
    options_for_select(
      Area.all.map do |area|
        [
          area.name,
          area.codes["gss"],
          {
            "data-country" => area.country_name,
            "data-type" => area.type,
          },
        ]
      end,
      Area.areas_for_edition(edition).map do |area|
        area.codes["gss"]
      end,
    )
  end

  def all_regions?(edition)
    Area.regions.map { |area|
      area.codes["gss"]
    }.sort == edition.area_gss_codes.sort
  end

  def english_regions?(edition)
    Area.english_regions.map { |area|
      area.codes["gss"]
    }.sort == edition.area_gss_codes.sort
  end
end
