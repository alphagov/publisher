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
      "Request sent to #{mail_to action.email_addresses}"
    elsif action.recipient_id.present?
      "Assigned to #{mail_to action.recipient.email, action.recipient.name}"
    end
  end

  def format_and_auto_link_plain_text(text)
    text = auto_link(escape_once(text), link: :urls, sanitize: false)
    simple_format(text, {}, :sanitize => false)
  end
end
