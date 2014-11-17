desc "Export all Editions that have an alternate title as a CSV"

task :export_alternate_title => :environment do
  require "csv"

  editions_with_alternative_titles = Edition.where(:alternative_title.nin => ["", nil]).map { |e|
    {
      bson_id: e.id.to_s,
      title: e.title,
      alternative_title: e.alternative_title,
      slug: e.slug,
    }
  }

  csv_string = CSV.generate do |csv|
    csv << ["bson_id", "title", "alternative_title", "slug"]

    editions_with_alternative_titles.each do |e|
      csv << [e[:bson_id], e[:title], e[:alternative_title], e[:slug]]
    end
  end

  puts csv_string
end
