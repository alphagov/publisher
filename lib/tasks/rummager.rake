namespace :rummager do
  desc "Reindex search engine"
  task :index => :environment do
    Rummageable.index Edition.search_index_all
  end
  desc "Show the output being sent to the search engine API"
  task :show_index => :environment do
    puts Edition.search_index_all.to_json
  end
end
