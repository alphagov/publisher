namespace :router do
  task :router_environment do
    Bundler.require :router, :default

    require 'logger'
    @logger = Logger.new STDOUT
    @logger.level = Logger::DEBUG

    @router = Router::Client.new :logger => @logger
  end

  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "frontend.#{platform}.alphagov.co.uk/"
    @logger.info "Registering application..."
    @router.applications.update application_id: "frontend", backend_url: url
  end

  task :register_routes => [ :router_environment, :environment ] do
    @logger.info "Registering homepage at /"
   @router.routes.update application_id: "frontend", route_type: :full,
     incoming_path: "/"

    @logger.info "Registering asset path /publisher-assets"
    @router.routes.update application_id: "frontend", route_type: :prefix,
      incoming_path: "/publisher-assets"
  end

  desc "Register publisher application and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end

