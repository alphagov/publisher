module ActionHelper
  def edition_actions(edition)
    edition.actions.reverse.delete_if do |a|
      [Action::IMPORTANT_NOTE, Action::IMPORTANT_NOTE_RESOLVED].include?(a.request_type)
    end
  end

  def action_note?(action)
    action.comment.present? || action.is_fact_check_request? || action.request_type == "assign"
  end

  def action_note(action)
    if action.comment.present?
      simple_format(escape_once(action.comment), {}, :sanitize => false)
    elsif action.is_fact_check_request? && action.email_addresses.present?
      "Request sent to #{mail_to action.email_addresses}"
    elsif action.recipient_id.present?
      "Assigned to #{mail_to action.recipient.email, action.recipient.name}"
    end
  end
end
