namespace :router_data do
  task export_multipart_redirects: [:environment] do
    artefacts = Artefact
      .multipart_formats
      .archived
      .with_redirect
      .order(slug: :ASC)
      .pluck(:slug, :redirect_url)

    filename = "/tmp/publisher_router_data_export.csv"

    puts "Writing file with #{artefacts.count} redirects"

    csv = "Source,Destination,Type\n"
    csv << artefacts
      .map { |arr| "/#{arr[0]},#{arr[1]},prefix" }
      .join("\n")

    File.write(filename, csv)

    puts "#{filename}"
    puts "Complete."
  end
end
