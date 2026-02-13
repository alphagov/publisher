module ActionHelper
  def edition_actions(edition, update_events)
    actions = edition.actions.reject do |a|
      [Action::IMPORTANT_NOTE, Action::IMPORTANT_NOTE_RESOLVED].include?(a.request_type)
    end
    update_actions = update_events.select { |e| e.is_for_edition?(edition) }.map(&:to_action)
    actions.append(*update_actions)
    actions.sort_by(&:created_at).reverse
  end

  def action_note?(action)
    action.comment.present? || action.is_fact_check_request? || action.request_type == "assign"
  end

  def action_note(action)
    notes = []

    if action.comment.present?
      case action.request_type
      when Action::RECEIVE_FACT_CHECK
        formatted_email_parts = format_email_text(action.comment)
        notes.concat(formatted_email_parts)
      when HostContentUpdateEvent::Action::CONTENT_BLOCK_UPDATE
        notes << content_block_update_comment(action)
      else
        notes << format_and_auto_link_plain_text(action.comment)
      end
    end

    if action.is_fact_check_request? && action.email_addresses.present?
      notes << tag.p("Request sent to #{mail_to action.email_addresses.gsub(/\s/, ''), action.email_addresses}".html_safe)
    end

    if action.recipient_id.present?
      notes << tag.p("Assigned to #{mail_to action.recipient.email, action.recipient.name}".html_safe)
    end

    notes.join.html_safe
  end

  def action_items(edition, update_events)
    items = []

    edition_actions(edition, update_events).map do |action|
      requester =
        if action.requester
          action.requester.name
        elsif action.requester_name
          action.requester_name
        else
          "GOV.UK Bot"
        end

      item = [
        sanitize("<div class='history__action--#{action.request_type}__heading'>
          <time class='govuk-body' datetime='#{action.created_at}'>#{action.created_at.to_fs(:govuk_date)}</time>
          <p class='govuk-body govuk-!-font-weight-bold'>#{action} by #{requester}</p>
        </div>"),
      ]

      if action_note?(action)
        warning = if action.comment_sanitized
                    sanitize("<div class='history__action--#{action.request_type}__warning'>#{render 'govuk_publishing_components/components/warning_text', {
                      text: 'We found some potentially harmful content in this email which has been automatically removed. Please check the content of the message in case any text has been deleted as well.',
                    }}</div>")
                  end

        comment = render "govuk_publishing_components/components/inset_text", {
          text: action_note(action),
        }

        item << sanitize(
          "<div class='history__action--#{action.request_type}__content'>
            #{warning if warning}
            <div class='history__action--#{action.request_type}__commment'>#{comment}</div>
          </div>",
        )
      end

      items << item.join.html_safe
    end

    items
  end

  def content_block_update_comment(action)
    "#{action.comment} (#{link_to 'View in Content Block Manager', action.block_url, target: '_blank', rel: 'noopener'})"
  end

  def action_class(action)
    action.request_type.tr("_", "-")
  end

  def format_and_auto_link_plain_text(text)
    text = auto_link(escape_once(text), link: :urls, sanitize: false)
    text = auto_link_zendesk_tickets(text)
    simple_format(text, {}, sanitize: false).html_safe
  end

  def auto_link_zendesk_tickets(text)
    text = text.gsub(/(?:zen|zendesk|zendesk ticket)(?:\s)?(?:#|:)?(?:\s)?(\d{4,})/i) do |match|
      ticket = Regexp.last_match(1)
      link_to match, "https://govuk.zendesk.com/tickets/#{ticket}"
    end

    text.html_safe
  end

  def format_email_text(text)
    email_parts = split_email_at_reply(text)
    formatted_email_parts = [format_and_auto_link_plain_text(email_parts.shift)]

    # if a reply was found
    unless email_parts.empty?
      formatted_email_parts << tag.div(
        format_and_auto_link_plain_text(email_parts.join("")),
        class: "js-earlier",
      )
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
