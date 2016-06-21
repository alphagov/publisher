namespace :local_transactions do

  desc "Download and import services, interactions and contacts"
  task :fetch => :environment do
    LocalAuthorityDataImporter.update_all
  end

  desc "Download and import services, interactions and contacts, and subsequently remove 'ghost' interactions"
  task :fetch_and_clean => :environment do
    Rake::Task["local_transactions:fetch"].invoke
    Rake::Task["check_for_ghosts:remove"].invoke
    Rake::Task["local_transactions:remove_old_services"].invoke
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

  desc "Removes services that do not appear in the service list CSV"
  task remove_old_services: :environment do
    LocalServiceCleaner.new.run
  end
end
