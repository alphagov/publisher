namespace :migrate do
  desc "Rename collection in local publisher database from whole_editions to editions"
  task :editions do
    Mongoid.load!("config/mongoid.yml")
    whole_editions = Mongoid.master.collection("whole_editions")

    # Only run if the old collection still exists.
    if whole_editions.count > 0
      whole_editions.rename("editions")
      puts "Renamed collection 'whole_editions' to 'editions'"
    else
      puts "The collection 'whole_editions' is empty, doing nothing."
    end
  end
end
