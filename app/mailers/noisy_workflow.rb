# encoding: utf-8

class NoisyWorkflow < ApplicationMailer
  include PathsHelper
  default from: "Winston (GOV.UK Publisher) <winston@alphagov.co.uk>"

  def make_noise(action, recipient_email)
    @action = action
    @preview_url = preview_edition_path(@action.edition)
    subject = "[PUBLISHER] #{describe_action(@action)}"
    mail(to: recipient_email, subject: subject)
  end

  def skip_review(action, recipient_email)
    @edition = action.edition
    @edition_url = edition_url(@edition.id, host: Plek.find("publisher"), external: true)
    mail(
      to: recipient_email,
      subject: "[PUBLISHER] Review has been skipped on #{@edition.title}",
    )
  end

  def request_fact_check(action, recipient_email)
    @edition = action.edition
    fact_check_address = @edition.fact_check_email_address
    mail(
      to: recipient_email,
      reply_to: fact_check_address,
      from: "GOV.UK Editorial Team <#{fact_check_address}>",
      subject: "‘[#{@edition.title}]’ GOV.UK preview of new edition [#{Rails.env}-#{@edition.id}]",
    ) do |format|
      format.text { render plain: action.customised_message }
    end
  end

  class NoMail
    # Provide a no-op object that has enough of the
    # ActionMailer::MessageDelivery API that callers who get one are
    # unlikely to react badly if we give them it
    def deliver_now; end

    def deliver_now!; end

    def deliver_later; end

    def deliver_later!; end

    def message; end

    def processed?; true; end
  end

  def report_errors(error_list)
    @errors = error_list
    mail(to: EMAIL_GROUPS[:dev], subject: "Errors in fact check email processing")
  end

protected

  def describe_action(action)
    edition = action.edition
    requester = action.requester
    recipient = action.recipient

    case action.request_type
    when Action::CREATE
      "Created #{edition.format_name}: \"#{edition.title}\" (by #{requester.name})"
    when Action::REQUEST_REVIEW
      "Review requested: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::APPROVE_REVIEW
      "Okayed for publication: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::APPROVE_FACT_CHECK
      "Fact check okayed for publication: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::REQUEST_AMENDMENTS
      "Amends needed: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::SEND_FACT_CHECK
      "Fact check requested: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::RECEIVE_FACT_CHECK
      "Fact check response: \"#{edition.title}\" (#{edition.format_name})"
    when Action::SKIP_FACT_CHECK
      "Skipped fact check: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::PUBLISH
      "Published: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::ARCHIVE
      "Archived: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::NEW_VERSION
      "New version: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::NOTE
      "Note added by #{requester.name}"
    when Action::RESEND_FACT_CHECK
      "Fact check resent: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
    when Action::ASSIGN
      if recipient
        "Assigned: \"#{edition.title}\" (#{edition.format_name}) to #{recipient.name}"
      else
        "Unassigned: \"#{edition.title}\" (#{edition.format_name})"
      end
    end
  end
end
