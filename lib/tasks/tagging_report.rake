desc "temporary rake task to see what mainstream content isn't tagged to a browse topic"
task tagging_report: :environment do
  latest_editions = Edition.published.select{|e| e.latest_edition? && e._type != "PopularLinksEdition"}
  english_only = latest_editions.reject{|e| e.artefact.welsh?}

  puts "#{english_only.count} English latest editions to process"

  editions_with_links_data =
    english_only.each_slice(100).flat_map do |slice|
      puts "fetching links"
      slice.map do |edition|
        {
          links: Services.publishing_api.get_links(edition.content_id),
          edition: edition,
        }
      end
    end

  not_tagged_to_browse =
    editions_with_links_data.reject do |edition|
      edition[:links].to_h["links"].keys.include? "mainstream_browse_pages"
    end

    puts "#{not_tagged_to_browse.count} Editions are not tagged to a browse topic"


  not_tagged_to_browse.each do |hash|
    puts "#{hash[:edition].title}, #{hash[:edition].slug}, #{hash[:edition].try(:assigned_to).try(:organisation_slug)}"
  end
end