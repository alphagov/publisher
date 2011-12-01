namespace :messenger do
  desc "Run queue consumer"
  task :listen => %w{listen:metadata_sync listen:router_bridge}

  namespace :listen do
    desc "Run queue consumer for metadata_sync"
    task :metadata_sync do
      Daemonette.run("publisher_metadata_sync") do
        Rake::Task["environment"].invoke
        logger = Logger.new File.join(Rails.root, "publisher_metadata_sync.log")
        logger.level = 0
        MetadataSync.new(logger).run
      end
    end

    desc "Run queue consumer for router_bridge"
    task :router_bridge do
      Daemonette.run("publisher_router_bridge") do
        Rake::Task["environment"].invoke
        log_file = File.join Rails.root, 'log', 'router_bridge.log'
        logger = Logger.new log_file
        logger.level = Logger::DEBUG
        router = Router::Client.new :logger => logger
        bridge = RouterBridge.new :router => router, :logger => logger
        bridge.run
      end
    end
  end
end
