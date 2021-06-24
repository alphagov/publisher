class AllUrlsPresenter < OrganisationContentPresenter
  def build_csv(csv)
    csv << column_headings.collect { |ch| ch.to_s.humanize }
    scope.each do |item|
      csv << build_row(item)

      next unless item.latest_edition.respond_to? :parts

      item.latest_edition.parts.each do |part|
        csv << build_row_for_part(part, item)
      end
    end
  end

  def build_row_for_part(part, parent)
    # Id,Name,Format,Slug,State,Browse pages,Topics,Organisations
    [part.id.to_s, part.title, "", "#{parent.slug}/#{part.slug}", "", "", "", ""]
  end
end
