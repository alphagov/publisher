require "gds_api/publishing_api"
require "gds_api/link_checker_api"

module Services
  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
    )
  end

  def self.link_checker_api
    @link_checker_api ||= GdsApi::LinkCheckerApi.new(
      Plek.new.find("link-checker-api"),
      bearer_token: ENV["LINK_CHECKER_API_BEARER_TOKEN"],
    )
  end
end
