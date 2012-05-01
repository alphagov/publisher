namespace :local_transactions do

  desc "Download the latest service list CSV from Local Directgov and import"
  task :fetch => :environment do
    LocalAuthorityDataImporter.update_all
  end
end
