namespace :local_transactions do

  desc "Download and import services, interactions and contacts"
  task :fetch => :environment do
    LocalAuthorityDataImporter.update_all
  end

  desc "Dowload the latest contact list CSV from Local Directgov and import"
  task :update_contacts => :environment do
    LocalContactImporter.update
  end

  desc "Download the latest interaction list CSV from Local Directgov and import"
  task :update_interactions => :environment do
    LocalInteractionImporter.update
  end

  desc "Import services from the service list CSV"
  task :update_services => :environment do
    LocalServiceImporter.update
  end
end
