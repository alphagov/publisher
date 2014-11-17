module ActionHelper
  def edition_actions(edition)
    edition.actions.reverse
  end

  def action_note?(action)
    action.comment.present? || action.is_fact_check_request? || action.request_type == "assign"
  end

  def action_note(action)
    notes = []
    notes << format_and_auto_link_plain_text(action.comment) if action.comment.present?

    if action.is_fact_check_request? && action.email_addresses.present?
      notes << content_tag(:p, "Request sent to #{mail_to action.email_addresses.gsub(/\s/,''), action.email_addresses}".html_safe)
    end

    if action.recipient_id.present?
      notes << content_tag(:p, "Assigned to #{mail_to action.recipient.email, action.recipient.name}".html_safe)
    end

    notes.join.html_safe
  end

  def format_and_auto_link_plain_text(text)
    text = auto_link(escape_once(text), link: :urls, sanitize: false)
    text = auto_link_zendesk_tickets(text)
    simple_format(text, {}, :sanitize => false).html_safe
  end

  def auto_link_zendesk_tickets(text)
    text = text.gsub(/(?:zen|zendesk|zendesk ticket)(?:\s)?(?:#|\:)?(?:\s)?(\d{4,})/i) do |match|
      ticket = $1
      link_to match, "https://govuk.zendesk.com/tickets/#{ticket}"
    end

    text.html_safe
  end
end
