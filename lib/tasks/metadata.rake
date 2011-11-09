namespace :metadata do
  desc "Synchronise metadata"
  task :sync do
    MetadataSync.new.run
  end
end
