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

    csv = "Source,Destination,Type,Segments\n"
    csv << artefacts
      .map { |arr| "/#{arr[0]},#{arr[1]},prefix#{segment(arr[1])}" }
      .join("\n")

    File.write(filename, csv)

    puts "#{filename}"
    puts "Complete."
  end

  def segment(redirect_url)
    redirect_url.include?('#') ? ',ignore' : ''
  end
end
