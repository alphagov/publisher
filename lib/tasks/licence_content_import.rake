namespace :licence_importer do
  desc "Predicts import outcome based on a dry run through the CSV data."
  task :report, [:data_path] => :environment do |t, args|
    LicenceContentImporter.run(:report, args[:data_path])
  end
  desc "Imports unwritten licence data from CSV."
  task :import, [:data_path, :importing_user] => :environment do |t, args|
    LicenceContentImporter.run(:import, args[:data_path], args[:importing_user])
  end
end
