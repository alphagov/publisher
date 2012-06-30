GDS::SSO.config do |config|
  config.user_model   = "User"
  config.oauth_id     = 'abcdefghjasndjkasndpublisher'
  config.oauth_secret = 'secret'
  config.oauth_root_url = Plek.current.find("signon")
  config.default_scope  = "Publisher"
end
