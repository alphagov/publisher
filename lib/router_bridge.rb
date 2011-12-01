class RouterBridge
  attr_accessor :router, :logger

  def initialize options = {}
    logger = options[:logger] || NullLogger.instance
    self.router = options[:router] || Router::Client.new(:logger => logger)
    self.logger = logger
  end

  def run
    transport = Messenger.transport
    marples = Marples::Client.new transport: transport, logger: logger

    marples.when 'publisher', '*', 'broadcast' do |publication|
      register_publication publication
    end

    marples.join
  end

  def register_publication publication
    register_route(
      :application_id => 'publisher',
      :incoming_path  => "/#{publication[:slug]}",
      :route_type     => :full
    )
    register_route(
      :application_id => 'publisher',
      :incoming_path  => "/#{publication[:slug]}.json",
      :route_type     => :full
    )
    register_route(
      :application_id => 'publisher',
      :incoming_path  => "/#{publication[:slug]}.xml",
      :route_type     => :full
    )
  end

  def register_route route
    logger.debug "Registering route #{route.inspect}"
    router.routes.update(route)
    logger.info "Registered #{route.inspect}"
  end
end
