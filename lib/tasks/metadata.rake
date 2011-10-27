namespace :metadata do
  task :sync => :environment do
    require 'metadata_sync'
    MetadataSync.new(Rails.logger).run
  end
end
