namespace :messenger do
  desc "Run queue consumer"
  task :listen  do
    Daemonette.run("publisher_metadata_sync") do
      Rake::Task["environment"].invoke
      MetadataSync.new.run
    end
  end
end
