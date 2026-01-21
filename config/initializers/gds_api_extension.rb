# This is a temporary extension to gds-api-adapters during Fact Check Manager's development phase
# Once the API adapter details are more settled, this should be migrated to the gem

# We may, at a later date, need to update this to include authentication
#
module GdsApi

  # Creates a GdsApi::FactCheckManager adapter
  #
  # @return [GdsApi::FactCheckManager]
  def self.fact_check_manager(options = {})
    GdsApi::FactCheckManager.new(Plek.find("fact-check-manager"), options)
  end
end