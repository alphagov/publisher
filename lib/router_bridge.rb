class RouterBridge
  attr_accessor :router, :logger

  def initialize options = {}
    logger = options[:logger] || Logger.new(STDOUT)
    logger.info("Initializing router bridge")
    self.router = options[:router] || Router::Client.new(:logger => logger)
    self.logger = logger
    logger.info("Done")
  end

  def register_all
    register_homepage
    register_publications
  end

  def register_homepage
    register_route(default_route_params.merge(:incoming_path => "/"))
  end

private
  def register_multi_part_publication(default_route_params, publication)
    logger.info(" Registering publication parts for #{publication['title']}")
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/print"))

    publication.parts.each do |part|
      logger.info(" Registering part #{part.slug}")
      register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/#{part.slug}"))
    end

    if publication.has_video?
      register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/video"))
    end
  end

  def register_programme(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/print"))
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/further-information"))
  end

  def register_local_transaction(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/not_found"))
  end

  def register_place(default_route_params, publication)
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}.kml"))
  end
  
  def register_publications
    logger.info "Registering #{Edition.published.count} publications"
    i = 0
    Edition.published.each do |p|
      register_publication(p)
      i += 1
    end
    logger.info "Registered #{i} publications"
  end

  def default_route_params
    {:application_id => 'frontend', :route_type => :full}
  end
  
  def register_publication(publication)
    logger.info("pub #{publication.inspect}")
    logger.info("Registering publication #{publication.title} with router as #{publication.class.to_s}")

    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}.json"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}.xml"))

    if publication.is_a?(GuideEdition)
      register_multi_part_publication(default_route_params, publication)
    elsif publication.is_a?(ProgrammeEdition)
      register_programme(default_route_params, publication)
    elsif publication.is_a?(LocalTransactionEdition)
      register_local_transaction(default_route_params, publication)
    elsif publication.is_a?(PlaceEdition)
      register_place(default_route_params, publication)
    end
  end

  def register_route route
    logger.info "Registering route #{route.inspect}"
    router.routes.update(route)
  end
end
