namespace :router do
  task :router_environment do
    require 'router'
    require 'logger'

    @logger = Logger.new STDOUT
    @logger.level = Logger::DEBUG

    puts("Configuring router client")
    @router = Router::Client.new :logger => @logger
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "frontend.#{platform}.alphagov.co.uk/"
    @logger.info "Registering application..."
    @router.applications.update application_id: "frontend", backend_url: url
  end

  task :register_routes => [:router_environment, :environment] do
  end

  desc "Register publisher application and routes with the router (run this task on server in cluster)"
  task :register => [:register_application, :register_routes]
end
