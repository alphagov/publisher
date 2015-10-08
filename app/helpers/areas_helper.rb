module AreasHelper
  def edition_areas_select_options(edition)
    options_for_select(
      Area.all.map { |area|
        [
          area.name,
          "#{area.slug};#{area.codes["gss"]}",
          {
            "data-country" => area.country_name,
            "data-type" => area.type,
          },
        ]
      },
      Area.areas_for_edition(edition).map { |area|
        "#{area.slug};#{area.codes["gss"]}"
      },
    )
  end

  def all_regions?(edition)
    Area.regions.map(&:slug).sort == edition.areas.sort
  end

  def english_regions?(edition)
    Area.english_regions.map(&:slug).sort == edition.areas.sort
  end
end
