namespace :licence_importer do
  desc "Predicts import outcome based on a dry run through the CSV data."
  task :report => :environment do
    LicenceContentImporter.run(:report)
  end
  desc "Imports unwritten licence data from CSV."
  task :import, [:importer] => :environment do |t, args|
    LicenceContentImporter.run(:import, args[:importer])
  end
end
