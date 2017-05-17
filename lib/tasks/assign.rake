namespace :assign do
  desc "Re-assign editions to new indexed columns"
  task migrate: :environment do
    require 'publication_assignment_migrator'
    PublicationAssignmentMigrator.migrate_all
  end
end
