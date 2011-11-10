namespace :messenger do
  desc "Run queue consumer"
  task :listen => :environment do
    Daemonette.run("publisher_metadata_sync") do
      MetadataSync.new.run
    end
  end
end
