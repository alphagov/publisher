namespace :assets do
  desc "Import assets"
  task :import => :environment do
    require 'import_assets'
    AssetImporter.perform
  end
end