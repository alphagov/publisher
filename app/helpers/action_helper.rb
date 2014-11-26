module ActionHelper
  def edition_actions(edition)
    edition.actions.reverse
  end

  def action_note?(action)
    action.comment.present? || action.is_fact_check_request? || action.request_type == "assign"
  end

  def action_note(action)
    notes = []

    if action.comment.present?
      if action.request_type == Action::RECEIVE_FACT_CHECK
        formatted_email_parts = format_email_text(action.comment)
        notes.concat(formatted_email_parts)
      else
        notes << format_and_auto_link_plain_text(action.comment)
      end
    end

    if action.is_fact_check_request? && action.email_addresses.present?
      notes << content_tag(:p, "Request sent to #{mail_to action.email_addresses.gsub(/\s/,''), action.email_addresses}".html_safe)
    end

    if action.recipient_id.present?
      notes << content_tag(:p, "Assigned to #{mail_to action.recipient.email, action.recipient.name}".html_safe)
    end

    notes.join.html_safe
  end

  def action_class(action)
    action.request_type.gsub(/_/, '-')
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

  def format_email_text(text)
    email_parts = split_email_at_reply(text)
    formatted_email_parts = [format_and_auto_link_plain_text(email_parts.shift)]

    # if a reply was found
    if email_parts.length > 0
      formatted_email_parts << link_to('Toggle earlier messages',
                  '#show-original',
                  class: 'original-message-toggle if-no-js-hide js-toggle')
      formatted_email_parts << content_tag(:div,
                  format_and_auto_link_plain_text(email_parts.join('')),
                  class: 'original-message if-js-hide js-toggle-target')
    end

    formatted_email_parts
  end

  # Based on common reply patterns
  # http://stackoverflow.com/questions/1372694/strip-signatures-and-replies-from-emails
  # https://github.com/github/email_reply_parser/blob/master/lib/email_reply_parser.rb
  #
  # Outlook: -----Original Message-----
  # OSX Mail: On [date] [someone] wrote:
  # Outlook variant: ________________________________
  #
  # Stops at first match
  def split_email_at_reply(text)
    text.split(/(-----Original Message-----|Sent from my iPhone|Sent from my BlackBerry|On\s.+?\n?.+?wrote:|________________________________)/, 2)
  end
end
