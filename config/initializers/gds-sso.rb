GDS::SSO.config do |config|
  config.user_model   = "User"
  config.oauth_id     = ENV['PUBLISHER_OAUTH_ID'] || "abcdefghjasndjkasndpublisher"
  config.oauth_secret = ENV['PUBLISHER_OAUTH_SECRET'] || "secret"
  config.oauth_root_url = Plek.current.find("signon")
end
