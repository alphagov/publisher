class FactCheckManagerApiService
  extend WorkingDaysHelper

  def self.request_fact_check(edition, requester, email_addresses)
    payload = build_post_payload(edition, requester, email_addresses)
    Services.fact_check_manager_api.post_fact_check(**payload)
  end

  def self.build_post_payload(edition, requester, email_addresses)
    { source_app: "publisher",
      source_id: edition.id,
      source_url: "#{Plek.find('publisher', external: true)}/editions/#{edition.id}",
      source_title: edition.title,
      requester_name: requester.name,
      requester_email: requester.email,
      current_content: edition.whole_body_hash,
      previous_content: edition.published_edition ? edition.published_edition.whole_body_hash : nil,
      deadline: working_days_after(Date.current, how_many: 5).to_fs(:iso8601),
      recipients: email_addresses.split(",").map(&:strip) }
  end
end
