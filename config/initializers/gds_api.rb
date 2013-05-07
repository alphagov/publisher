require 'gds_api/base'
require 'gds_api/asset_manager'
require 'attachable'
require 'plek'

GdsApi::Base.logger = Logger.new(Rails.root.join("log/#{Rails.env}.api_client.log"))

Attachable.asset_api_client = GdsApi::AssetManager.new(Plek.current.find('asset-manager'))
