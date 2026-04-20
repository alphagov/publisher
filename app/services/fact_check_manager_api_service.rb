class FactCheckManagerApiService
  extend WorkingDaysHelper

  SOURCE_APP = "publisher".freeze

  def self.request_fact_check(edition, requester, email_addresses)
    payload = build_post_payload(edition, requester, email_addresses)
    Services.fact_check_manager_api.post_fact_check(**payload)
  end

  def self.resend_fact_check_emails(edition)
    Services.fact_check_manager_api.post_resend_emails(source_app: SOURCE_APP, source_id: edition.id)
  end

  def self.build_post_payload(edition, requester, email_addresses)
    current_content_presenter = Formats::GenericEditionPresenter.new(edition)
    previous_content = {}
    if edition.published_edition
      previous_content_presenter = Formats::GenericEditionPresenter.new(edition.published_edition)
      previous_content = previous_content_presenter.render_for_fact_check_manager_api
    end

    { source_app: SOURCE_APP,
      source_id: edition.id,
      source_url: "#{Plek.find('publisher', external: true)}/editions/#{edition.id}",
      source_title: edition.title,
      requester_name: requester.name,
      requester_email: requester.email,
      current_content: current_content_presenter.render_for_fact_check_manager_api,
      previous_content: previous_content,
      deadline: working_days_after(Date.current, how_many: 5).to_fs(:iso8601),
      recipients: email_addresses.split(",").map(&:strip),
      draft_auth_bypass_id: edition.auth_bypass_id,
      draft_content_id: edition.content_id,
      draft_slug: edition.slug }
  end

  def self.update_fact_check_content(edition)
    current_content_presenter = Formats::GenericEditionPresenter.new(edition)

    Services.fact_check_manager_api.patch_update_content(
      source_app: SOURCE_APP,
      source_id: edition.id,
      source_title: edition.title,
      current_content: current_content_presenter.render_for_fact_check_manager_api,
      draft_auth_bypass_id: edition.auth_bypass_id,
      draft_slug: edition.slug,
    )
  end
end
