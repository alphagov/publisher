namespace :router do
  desc "Register homepage and all publications with router"
  task :register => %w{register:homepage register:publications}

  namespace :register do
    desc "Register homepage with router"
    task :homepage => :environment do
      RouterBridge.instance.register_homepage
    end

    desc "Register all publications with router"
    task :publications => :environment do
      RouterBridge.instance.register_publications
    end
  end
end
