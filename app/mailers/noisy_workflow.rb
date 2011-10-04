# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "winston@alphagov.co.uk"
  
  def make_noise(publication,action)
    @publication = publication
    @action = action
    
    email_address = case action.request_type
    when Action::PUBLISHED then "team@alphagov.co.uk"
    when Action::REVIEW_REQUESTED then "eds@alphagov.co.uk, seo@alphagov.co.uk"
    else "eds@alphagov.co.uk"
    end

    mail(:to => email_address,
         :subject => "[PUBLISHER] #{@action.friendly_description}: #{@action.edition.title}")
  end
  
  def request_fact_check(edition, email_addresses)
    @edition = edition
    fact_check_address = "factcheck+#{Rails.env}-#{edition.container.id}@alphagov.co.uk"
    mail(
      :to => email_addresses,
      :reply_to => fact_check_address,
      :from => "Gov.UK Editors <#{fact_check_address}>",
      :subject => "[FACT CHECK REQUESTED] #{edition.title} (id:#{edition.fact_check_id})") unless email_addresses.blank?
  end
  
end
