class MultiNoisyWorkflow < ApplicationMailer
  def self.make_noise(action, mailer: NoisyWorkflow)
    recipient_emails = (EMAIL_GROUPS[:citizen] + EMAIL_GROUPS[:business]).uniq

    recipient_emails.map do |recipient_email|
      mailer.make_noise(action, recipient_email)
    end
  end

  def self.skip_review(action, mailer: NoisyWorkflow)
    recipient_emails = EMAIL_GROUPS[:force_publish_alerts]

    recipient_emails.map do |recipient_email|
      mailer.skip_review(action, recipient_email)
    end
  end

  def self.request_fact_check(action, mailer: NoisyWorkflow)
    action.email_addresses.split(/,\s*/).map do |recipient_email|
      mailer.request_fact_check(action, recipient_email)
    end
  end

  def self.resend_fact_check(action)
    edition = action.edition
    latest_status_action = edition.latest_status_action
    if latest_status_action.is_fact_check_request? && action.request_type == Action::RESEND_FACT_CHECK
      self.request_fact_check(latest_status_action)
    else
      Rails.logger.info("Asked to resend fact check for #{edition.content_id}, but its most recent status action is not a fact check, it's a #{latest_status_action.request_type}")
      NoisyWorkflow::NoMail.new
    end
  end
end
