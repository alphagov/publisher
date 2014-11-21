namespace :business_support_content do
  desc "Adds regional data to BusinessSupportEditions"
  task :import_areas, [:data_path] => :environment do |t, args|
    BusinessSupportAreasImporter.run(args[:data_path])
  end
end
