class EventNotifierService
  def self.any_action(action, mailer: EventMailer)
    recipient_emails = (EMAIL_GROUPS[:citizen] + EMAIL_GROUPS[:business]).uniq

    emails = recipient_emails.map do |recipient_email|
      mailer.any_action(action, recipient_email)
    end

    emails.map(&:deliver_now)
  end

  def self.skip_review(action, mailer: EventMailer)
    recipient_emails = EMAIL_GROUPS[:force_publish_alerts]

    emails = recipient_emails.map do |recipient_email|
      mailer.skip_review(action, recipient_email)
    end

    emails.map(&:deliver_now)
  end

  def self.request_fact_check(action, mailer: EventMailer)
    emails = action.email_addresses.split(/,\s*/).map do |recipient_email|
      mailer.request_fact_check(action, recipient_email)
    end

    emails.map(&:deliver_now)
  end

  def self.resend_fact_check(action)
    edition = action.edition
    latest_status_action = edition.latest_status_action
    if latest_status_action.is_fact_check_request? && action.request_type == Action::RESEND_FACT_CHECK
      request_fact_check(latest_status_action)
    else
      Rails.logger.info("Asked to resend fact check for #{edition.content_id}, but its most recent status action is not a fact check, it's a #{latest_status_action.request_type}")
    end
  end
end
