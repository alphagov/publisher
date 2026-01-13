require "gds_api/base"

class GdsApi::FactCheckManager < GdsApi::Base
  # Post details to open a new fact check request
  #
  # @param [uuid] edition_id The unique ID for the edition
  # @param [string] edition_title The title of the edition
  # @param [string] requester_name The username of the Publisher user submitting the request
  # @param [array] recipients Array of emails to be notified of the request
  # @param [string] current_content String containing HTML content being fact checked
  # @param [datetime] deadline Time a response is requested by
  # @option [string] previous_published_edition String containing HTML content of previous edition to check against
  #
  #
  # @return [GdsApi::Response] A response containing a unique ID for the fact check request if successful
  def post_fact_check(edition_id, edition_title, requester_name, recipients, current_content, deadline, previous_published_edition = nil)
    post_json(
      "#{endpoint}",
      edition_id:,
      edition_title:,
      requester_name:,
      recipients:,
      current_content:,
      previous_published_edition:,
      deadline:
    )
  end
end
