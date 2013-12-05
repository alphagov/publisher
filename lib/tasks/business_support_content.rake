namespace :business_support_content do
  desc "Performs a dry run through the CSV data."
  task :report, [:data_path] => :environment do |t, args|
    BusinessSupportImporter.run(:report, args[:data_path])
  end

  desc "Imports unwritten business support data from CSV."
  task :import, [:data_path, :importing_user] => :environment do |t, args|
    BusinessSupportImporter.run(:import, args[:data_path], args[:importing_user])
  end

  desc "Imports Imminence facet data into the corresponding BusinessSupportEdition"
  task :import_facet_data => :environment do
    BusinessSupportFacetDataImporter.run
  end
end
