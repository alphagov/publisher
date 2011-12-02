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

  def register_publication publication
    register_route(
      :application_id => 'frontend',
      :incoming_path  => "/#{publication['slug']}",
      :route_type     => :full
    )
    register_route(
      :application_id => 'frontend',
      :incoming_path  => "/#{publication['slug']}.json",
      :route_type     => :full
    )
    register_route(
      :application_id => 'frontend',
      :incoming_path  => "/#{publication['slug']}.xml",
      :route_type     => :full
    )
  end

  def register_route route
    logger.debug "Registering route #{route.inspect}"
    router.routes.update(route)
    logger.info "Registered #{route.inspect}"
  end
end
