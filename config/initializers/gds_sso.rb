GDS::SSO.config do |config|
  config.api_request_matcher = ->(request) { request.path.start_with?("/api/") }
  config.additional_mock_permissions_required = %w[internal_app]
end
