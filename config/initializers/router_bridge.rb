def create_router_bridge
  router_uri = Rails.env.development? ? "http://cache.cluster:4000/router" : "http://cache.cluster:8080/router"
  router_client = Router::Client.new :logger
  RouterBridge.new(router_client)
end
RouterBridge.instance = create_router_bridge
