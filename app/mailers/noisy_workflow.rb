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
  
  def request_fact_check(edition, details)
    @edition = edition
    fact_check_address = "factcheck+#{Rails.env}-#{edition.container.id}@alphagov.co.uk"
    unless details[:email_addresses].blank?
      mail(:to => details[:email_addresses], :reply_to => fact_check_address, 
        :from => "Beta Editorial Team <#{fact_check_address}>", 
        :subject => "[FACT CHECK REQUESTED] #{edition.title}") do |format|
       format.text { render :text => details[:customised_message] }
     end
   end
         
  end
  
end
