class RouterBridge
  attr_accessor :router, :logger, :marples

  def initialize options = {}
    logger = options[:logger] || Logger.new(STDOUT)
    logger.info("Initializing router bridge")
    self.router = options[:router] || Router::Client.new(:logger => logger)
    self.logger = logger
    self.marples = options[:marples_client] || Marples::Client.new(transport: Messenger.transport, logger: logger)
    logger.info("Done")
  end

  def run
    marples.when 'publisher', '*', 'published' do |publication_hash|
      begin
        publication_id = publication_hash['_id']
        logger.info("Recieved message for #{publication_hash['title']} #{publication_id}")
        publication = WholeEdition.find(publication_id)

        if (publication.nil?)
          logger.warn("Could not find publication #{publication_id}")
        else
          register_publication(publication)
        end
      rescue => e
        logger.error("Exception caused while processing message for #{publication_hash.inspect} #{e.message}")
      end
    end

    marples.join
  end

  private
  def register_multi_part_publication(default_route_params, publication)
    logger.info(" Registering publication parts for #{publication['title']}")
    register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/print"))

    publication.parts.each do |part|
      logger.info(" Registering part #{part.slug}")
      register_route(default_route_params.merge(:incoming_path => "/#{publication.slug}/#{part.slug}"))
    end

    # end

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

  def register_publication(publication)
    logger.info("pub #{publication.inspect}")
    logger.info("Registering publication #{publication.title} with router as #{publication.class.to_s}")

    default_route_params = {:application_id => 'frontend', :route_type => :full}
    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}.json"))
    register_route(default_route_params.merge(:incoming_path  => "/#{publication.slug}.xml"))

    if publication.is_a?(GuideEdition)
      register_multi_part_publication(default_route_params, publication)
    elsif publication.is_a?(ProgrammeEdition)
      register_programme(default_route_params, publication)
    elsif publication.is_a?(LocalTransactionEdition)
      register_local_transaction(default_route_params, publication)
    end
  end

  def register_route route
    logger.info "Registering route #{route.inspect}"
    router.routes.update(route)
  end
end
