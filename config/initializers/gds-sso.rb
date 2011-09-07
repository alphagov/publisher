GDS::SSO.config do |config|
  config.user_model   = 'User'
  # set up ID and Secret in a way which doesn't require it to be checked in to source control...
  config.oauth_id     = ENV['OAUTH_ID']
  config.oauth_secret = ENV['OAUTH_SECRET']
  # optional config for location of sign-on-o-tron
  config.oauth_root_url = "http://signonotron.dev.gov.uk"
end
