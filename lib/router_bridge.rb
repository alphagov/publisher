class RouterBridge
  attr_accessor :router, :logger, :marples

  def initialize options = {}
    logger = options[:logger] || NullLogger.instance
    self.router = options[:router] || Router::Client.new(:logger => logger)
    self.logger = logger
    self.marples = options[:marples_client] || Marples::Client.new(transport: Messenger.transport, logger: logger
)
  end

  def run
    transport = Messenger.transport

    marples.when 'publisher', '*', 'published' do |publication|
      register_publication publication
    end

    marples.join
  end

  def register_multi_part_publication(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}/print"))

    publication.published_edition.parts.each do |part|
      register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}/#{part['slug']}"))
    end
    
    if publication.has_video?
      register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}/video"))
    end
  end
  
  def register_programme(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}/print"))
    
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}/further-information"))
  end
  
  def register_local_transaction(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path => "/#{publication['slug']}/not_found"))
  end
    
  def register_publication publication
    default_route_params = {:application_id => 'frontend', :route_type => :full}
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}.json"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication['slug']}.xml"))
    
    if publication.is_a?(Guide)
      register_multi_part_publication(default_route_params, publication)
    elsif publication.is_a?(Programme)
      register_programme(default_route_params, publication)
    elsif publication.is_a?(LocalTransaction)
      register_local_transaction(default_route_params, publication)
    end
  end

  def register_route route
    logger.debug "Registering route #{route.inspect}"
    router.routes.update(route)
    logger.info "Registered #{route.inspect}"
  end
end
