module ActionHelper
  def edition_actions(edition)
    edition.actions.reverse
  end

  def action_note?(action)
    action.comment.present? || action.is_fact_check_request? || action.request_type == "assign"
  end

  def action_note(action)
    if action.comment.present?
      format_and_auto_link_plain_text(action.comment)
    elsif action.is_fact_check_request? && action.email_addresses.present?
      "Request sent to #{mail_to action.email_addresses}".html_safe
    elsif action.recipient_id.present?
      "Assigned to #{mail_to action.recipient.email, action.recipient.name}".html_safe
    end
  end

  def format_and_auto_link_plain_text(text)
    text = auto_link(escape_once(text), link: :urls, sanitize: false)
    text = auto_link_zendesk_tickets(text)
    simple_format(text, {}, :sanitize => false).html_safe
  end

  def auto_link_zendesk_tickets(text)
    text.gsub(/(?:zen|zendesk|zendesk ticket)(?:\s)?(?:#|\:)?(?:\s)?(\d{4,})/i) do |s|
      ticket = $1
      "<a href=\"https://govuk.zendesk.com/tickets/#{ticket}\">#{s}</a>"
    end
  end
end
