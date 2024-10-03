desc "temporary rake task to see what mainstream content isn't tagged to a browse topic"
task tagging_report: :environment do
  latest_editions = Edition.published.select { |e| e.latest_edition? && e._type != "PopularLinksEdition" }
  english_only = latest_editions.reject { |e| e.artefact.welsh? }

  puts "#{english_only.count} English latest editions to process"

  editions_with_links_data =
    english_only.each_slice(100).flat_map do |slice|
      puts "fetching links"
      slice.map do |edition|
        {
          links: Services.publishing_api.get_links(edition.content_id),
          edition:,
        }
      end
    end

  not_tagged_to_browse =
    editions_with_links_data.reject do |edition|
      edition[:links].to_h["links"].keys.include? "mainstream_browse_pages"
    end

  puts "#{not_tagged_to_browse.count} Editions are not tagged to a browse topic"

  not_tagged_to_browse.each do |hash|
    org_names = []
    if hash[:links]["links"]["organisations"]
      hash[:links]["links"]["organisations"].each do |organisation_id|
        org_name = Services.publishing_api.get_content(organisation_id).to_h["title"].gsub(",", " ")
        org_names << org_name # Add the organization name to the array
      end
    end

    org_names_string = org_names.join(", ")

    puts "#{hash[:edition].title.gsub(',', ' ')}, #{hash[:edition].slug.gsub(',', ' ')}, #{org_names_string}"
  end
end
