GDS::SSO.config do |config|
  config.user_model   = "User"
  config.oauth_id     = ENV['PUBLISHER_OAUTH_ID']
  config.oauth_secret = ENV['PUBLISHER_OAUTH_SECRET']
  config.oauth_root_url = Plek.current.find("signon")
  config.basic_auth_user = ENV['PANOPTICON_USER']
  config.basic_auth_password = ENV['PANOPTICON_PASSWORD']
end