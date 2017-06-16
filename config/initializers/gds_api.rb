# This file is overwritten on deploy (see alphagov-deployment), so be careful
# about relying on this content

require 'gds_api/base'
require 'gds_api/asset_manager'
require 'plek'

GdsApi::Base.logger = Logger.new(Rails.root.join("log/#{Rails.env}.api_client.log"))

# Need to provide a bearer token to authenticate to the asset manager.
# This can be loaded from an environment variable, or this file can
# be overwritten with the correct details on deploy.
# See README.md for details of how to generate a bearer token.

Attachable.asset_api_client = GdsApi::AssetManager.new(Plek.current.find('asset-manager'), bearer_token: ENV['PUBLISHER_ASSET_MANAGER_CLIENT_BEARER_TOKEN'] || 'also_set_at_deploy_time',)
