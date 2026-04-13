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
  # @param [hash] current_content Hash of current content to be compared in HTML format
  #   For simple single-part documents format: { id: { heading: "heading string", body: "HTML content string" } }
  #   For complex multi-part/multi-chapter documents format: { id: { heading: "heading string", body: "HTML content string" }, id2: { heading: "heading string", body: "HTML content string" }, ...}.
  #   Heading or body may change between current_content and previous_content, but the ID for the parts must match to allow for comparison.
  #   If a part has been deleted entirely, do not provide its ID in current_content.
  # @option [hash] previous_content Same format as current_content
  #   If a new part has been added to the document, do not provide its ID in previous_content.
  # @option [string] deadline Date a response is requested by. Use iso8601 date format: "2026-02-09"
  # @param [array] recipients Array of emails to be notified of the request
  # @option [uuid] draft_auth_bypass_id The edition's auth_bypass_id for draft origin preview access
  # @option [uuid] draft_content_id The edition's content_id for draft origin preview access
  # @option [string] draft_slug The edition's slug for the draft origin preview URL path
  #
  # @return [GdsApi::Response] Basic response with code

  def post_fact_check(source_app:, source_id:, requester_name:, requester_email:, current_content:,
                      recipients:, source_title: nil, source_url: nil, previous_content: {}, deadline: nil,
                      draft_auth_bypass_id: nil, draft_content_id: nil, draft_slug: nil)
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
      draft_auth_bypass_id:,
      draft_content_id:,
      draft_slug:,
    )
  end

  # Post a request to resend fact check emails for an existing fact check request
  #
  # Keyword Arguments:
  # @param [string] source_app identifier for the application that created the request
  # @param [uuid] source_id The unique ID for the content
  #
  # @return [GdsApi::Response] Basic response with code

  def post_resend_emails(source_app:, source_id:)
    post_json("#{endpoint}/api/requests/#{source_app}/#{source_id}/resend-emails")
  end

  # Patch a request to update the content for an existing fact check request
  #
  # Keyword Arguments:
  # @param [string] source_app identifier for the application sending the request
  # @param [uuid] source_id The unique ID for the content
  # @param [hash] current_content Hash of current content to be compared in HTML format
  #   For simple single-part documents format: { id: { heading: "heading string", body: "HTML content string" } }
  #   For complex multi-part/multi-chapter documents format: { id: { heading: "heading string", body: "HTML content string" }, id2: { heading: "heading string", body: "HTML content string" }, ...}.
  #   If a part has been deleted entirely, do not provide its ID in current_content.
  # @option [string] source_title The title of the content (optional)
  # @option [uuid] draft_auth_bypass_id The edition's auth_bypass_id for draft origin preview access (optional)
  # @option [string] draft_slug The edition's slug for the draft origin preview URL path (optional)
  def patch_update_content(source_app:, source_id:, current_content:, source_title: nil, draft_auth_bypass_id: nil, draft_slug: nil)
    payload = {
      source_title:,
      current_content:,
      draft_auth_bypass_id:,
      draft_slug:,
    }.compact

    patch_json("#{endpoint}/api/requests/#{source_app}/#{source_id}", payload)
  end
end
