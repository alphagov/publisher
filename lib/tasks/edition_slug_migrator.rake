require 'edition_slug_migrator'

namespace :edition_slug_migrator do
  desc "Migrate the edition slugs specified in data/slugs_to_migrate.json"
  task :run => :environment do
    EditionSlugMigrator.new.run
  end
end
