require "gds_api/base"

class GdsApi::FactCheckManager < GdsApi::Base
  # Post details to open a new fact check request
  #
  # Keyword Arguments:
  # @param [string] source_app identifier for the application sending the request
  # @param [uuid] source_id The unique ID for the content
  # @option [string] source_title The title of the content
  # @option [string] source_url The url locating the content on the source application
  # @param [string] requester_name The username of the source app user submitting the request
  # @param [string] requester_email The email address of the source app user submitting the request
  # @param [string] current_content String containing HTML content being fact checked
  # @option [string] previous_content String containing HTML content of previous content version to check against
  # @option [string] deadline Date a response is requested by. Use iso8601 date format: "2026-02-09"
  # @param [array] recipients Array of emails to be notified of the request
  #
  # @return [GdsApi::Response] Basic response with code

  def post_fact_check(source_app:, source_id:, requester_name:, requester_email:, current_content:,
                      recipients:, source_title: nil, source_url: nil, previous_content: nil, deadline: nil)
    post_json(
      "#{endpoint}/api/requests",
      source_app:,
      source_id:,
      source_title:,
      source_url:,
      requester_name:,
      requester_email:,
      current_content:,
      previous_content:,
      deadline:,
      recipients:,
    )
  end
end
