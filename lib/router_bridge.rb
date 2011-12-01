class RouterBridge
  attr_accessor :router_client, :logger, :env
  class_attribute :instance

  def initialize(router_client, options = {})
    self.router_client = router_client
    self.env = options[:env] || ENV
    self.logger = options[:logger] || NullLogger.instance
  end

  def listen(marples_client = nil)
    marples_client ||= default_marples_client
    register_application

    marples_client.when('publisher', '*', 'published') do |publication|
      register_publication(publication)
    end

    marples_client.join
  end

  def default_marples_client
    Marples::Client.new(Messenger.transport, 'publisher', logger)
  end

  def register_publications
    logger.info "Registering #{Publication.published.count} publications"
    i = 0
    Publication.published.each do |p|
      register_publication(p.attributes)
      i += 1
    end
    logger.info "Registered #{i} publications"
  end

  def register_homepage
    register_application
    register_route(
      :application_id => application_id,
      :incoming_path  => "/",
      :route_type     => :full
    )
  end

  def register_publication(publication)
    register_application
    register_route(
      :application_id => application_id,
      :incoming_path  => "/#{publication[:slug]}",
      :route_type     => :full
    )
  end

  def register_route(route)
    logger.debug "Registering route #{route[:incoming_path]} to point to #{application_id}"
    router_client.routes.create(route)
    logger.info "Registered #{route[:incoming_path]} pointing to #{application_id}"
  rescue Router::Conflict
    logger.debug "The router already knows about #{route[:incoming_path]}. Ignoring"
  rescue => e
    logger.error "Error when registering route #{route[:incoming_path]}: #{e}"
  end

private
  def register_application
    logger.debug "Registering application #{application}"
    router_client.applications.create(application)
  rescue Router::Conflict
    existing = router_client.applications.find(application[:application_id])
    logger.debug "Application #{application[:application_id]} already registered as #{existing}"
  end

  def application
    {
      application_id: "frontend",
      backend_url: "frontend.#{env['FACTER_govuk_platform']}.alphagov.co.uk/"
    }
  end

  def application_id
    application[:application_id]
  end
end
