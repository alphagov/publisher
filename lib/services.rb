require "gds_api/publishing_api_v2"

module Services
  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(Plek.find("publishing-api"))
  end
end
