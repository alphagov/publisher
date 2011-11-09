require "metadata_sync"

namespace :metadata do
  desc "Synchronise metadata"
  task :sync do
    Daemonette.run("publisher_metadata_sync") do
      MetadataSync.new.run
    end
  end
end
