require 'gds_api/base'
require 'gds_api/asset_manager'
require 'attachable'
require 'plek'

GdsApi::Base.logger = Logger.new(Rails.root.join("log/#{Rails.env}.api_client.log"))

# Need to provide a bearer token to authenticate to the asset manager and panopticon.
# This can be loaded from an environment variable, or this file can
# be overwritten with the correct details on deploy.
# See README.md for details of how to generate a bearer token.
options = {
  bearer_token: ENV['PUBLISHER_API_CLIENT_BEARER_TOKEN'] || 'set_at_deploy_time'
}

Attachable.asset_api_client = GdsApi::AssetManager.new(Plek.current.find('asset-manager'), options)
PANOPTICON_API_CREDENTIALS = options
