module AreasHelper
  def edition_areas_json(edition)
    areas = Area.areas_for_edition(edition)
    areas.map { |a| { id: a.slug, text: a.name } }.to_json
  end

  def all_regions?(edition)
    Area.regions.map(&:slug).sort == edition.areas.sort
  end

  def english_regions?(edition)
    Area.english_regions.map(&:slug).sort == edition.areas.sort
  end
end
