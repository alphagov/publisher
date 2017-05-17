namespace :local_transactions do
  desc "Imports services and removes any old ones"
  task fetch_and_clean: :environment do
    Rake::Task["local_transactions:update_services"].invoke
    Rake::Task["local_transactions:remove_old_services"].invoke
  end

  desc "Import services from the service list CSV"
  task update_services: :environment do
    LocalServiceImporter.update
  end

  desc "Removes services that do not appear in the service list CSV"
  task remove_old_services: :environment do
    LocalServiceCleaner.new.run
  end
end
