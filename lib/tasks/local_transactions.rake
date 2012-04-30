namespace :local_transactions do

  desc "Download the latest service list CSV from Local Directgov and import"
  task :fetch => :environment do
    LocalServiceImporter.update
    LocalInteractionImporter.update
    LocalContactImporter.update
  end
end
