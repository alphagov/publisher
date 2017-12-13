module ActionProcessorHelpers
  def request_review(user, edition)
    user.progress(edition, request_type: :request_review, comment: "Review this edition please.")
  end

  def approve_review(user, edition)
    user.progress(edition, request_type: :approve_review, comment: "I've reviewed it")
  end

  def send_fact_check(user, edition, comment = "Fact check this guide please.")
    user.progress(edition, request_type: :send_fact_check, comment: comment, email_addresses: "test@test.com")
  end

  def resend_fact_check(user, edition)
    user.progress(edition, request_type: :resend_fact_check)
  end

  def receive_fact_check(user, edition, comment = "Please verify these facts.")
    user.progress(edition, request_type: :receive_fact_check, comment: comment)
  end

  def approve_fact_check(user, edition, comment = "No changes needed, this is all correct")
    user.progress(edition, request_type: :approve_fact_check, comment: comment)
  end

  def request_amendments(user, edition)
    user.progress(edition, request_type: :request_amendments, comment: "More amendments are required")
  end

  def publish(user, edition, comment = 'Yo!')
    user.progress(edition, request_type: :publish, comment: comment)
  end

  def schedule_for_publishing(user, edition, action_attributes)
    user.progress(edition, request_type: :schedule_for_publishing,
      publish_at: action_attributes[:publish_at] || Time.zone.now.utc,
      comment: action_attributes[:comment] || 'Schedule!')
  end

  def skip_review(user, edition)
    user.progress(edition, request_type: :skip_review, comment: "Skipping review as this is an out of hours urgent update.")
  end
end
