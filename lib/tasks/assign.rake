namespace :assign do
  desc "Re-assign editions to new indexed columns"
  task :migrate => :environment do
    PublicationAssignmentMigrator.migrate_all
  end
end