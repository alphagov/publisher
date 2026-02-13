GDS::SSO.config do |config|
  config.api_request_matcher = ->(request) { request.path.start_with?("/api/") }
end
