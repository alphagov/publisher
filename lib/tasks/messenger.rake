namespace :messenger do
  desc "Run queue consumer"
  task :listen  do
    Daemonette.run("publisher_metadata_sync") do
      Rake::Task["environment"].invoke
      MetadataSync.new.run
    end

    Daemonette.run("publisher_publication_listener") do
      Rake::Task["environment"].invoke
      PublicationListener.new.run
    end

    Daemonette.run("publisher_destruction_listener") do
      Rake::Task["environment"].invoke
      DestructionListener.new.run
    end
  end
end
