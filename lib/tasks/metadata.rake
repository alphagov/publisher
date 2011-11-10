namespace :metadata do
  desc "Synchronise metadata"
  task :sync => :environment do
    Daemonette.run("publisher_metadata_sync") do
      MetadataSync.new.run
    end
  end
end
