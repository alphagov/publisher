# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "Winston (GOV.UK Publisher) <winston@alphagov.co.uk>"

  def make_noise(action)
    @action = action

    if action.edition.business_proposition
      subject = "[PUBLISHER]-BUSINESS #{describe_action(@action)}"
      recipient_emails = EMAIL_GROUPS[:business]
    else
      subject = "[PUBLISHER] #{describe_action(@action)}"
      recipient_emails = EMAIL_GROUPS[:citizen]
    end

    mail(:to => recipient_emails.join(', '), :subject => subject)
  end

  def request_fact_check(action)
    @edition = action.edition
    fact_check_address = @edition.fact_check_email_address
    mail(:to => action.email_addresses, :reply_to => fact_check_address,
      :from => "GOV.UK Editorial Team <#{fact_check_address}>",
      :subject => "[FACT CHECK REQUESTED] #{@edition.title}") do |format|
     format.text { render :text => action.customised_message }
    end
  end

  def report_errors(error_list)
    @errors = error_list
    mail(:to => EMAIL_GROUPS[:dev], :subject => 'Errors in fact check email processing')
  end

  protected
  def describe_action(action)
    edition = action.edition
    requester = action.requester
    recipient = action.recipient

    case action.request_type
    when Action::CREATE
      "Created #{edition.format_name}: \"#{edition.title}\" (by #{requester.name})"
    when Action::START_WORK
      "Work started: \"#{edition.title}\" (#{edition.format_name}) by #{requester.name}"
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
    when Action::ASSIGN
      "Assigned: \"#{edition.title}\" (#{edition.format_name}) to #{recipient.name}"
    end
  end
end
