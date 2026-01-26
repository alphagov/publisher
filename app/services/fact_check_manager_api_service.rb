class FactCheckManagerApiService
  def self.request_fact_check(edition, requester, email_addresses)
    payload = build_post_payload(edition, requester, email_addresses)
    Services.fact_check_manager_api.post_fact_check(*payload)
  end

  def self.build_post_payload(edition, requester, email_addresses)
    [edition.id,
     edition.title,
     requester.name,
     requester.email,
     edition.whole_body,
     edition.published_edition ? edition.published_edition.whole_body : "",
     Time.zone.now + 5.days,
     email_addresses,
    ]
  end
end
