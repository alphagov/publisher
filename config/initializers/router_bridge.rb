def create_router_bridge
  router_uri = Rails.env.development? ? "http://cache.cluster:4000/router" : "http://cache.cluster:8080/router"
  http_client = Router::HttpClient.new(router_uri, Rails.logger)
  router_client = Router::Client.new(http_client)
  RouterBridge.new(router_client)
end
RouterBridge.instance = create_router_bridge