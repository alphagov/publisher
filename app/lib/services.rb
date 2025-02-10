require "gds_api/publishing_api"

module Services
  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(
      Plek.find("publishing-api"),
      bearer_token: ENV.fetch("PUBLISHING_API_BEARER_TOKEN", "example"),
    )
  end

  def self.signon_api
    @signon_api ||= GdsApi::SignonApi.new(
      Plek.find("signon", external: true),
      bearer_token: ENV.fetch("SIGNON_API_BEARER_TOKEN", "example"),
    )
  end
end
