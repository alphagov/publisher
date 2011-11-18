# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "Winston (Gov.UK Publisher) <winston@alphagov.co.uk>"
  
  def make_noise(publication, action)
    @publication = publication
    @action = action
                                                  
    case Plek.current.environment
    when 'preview' 
      email_address = 'dev@alphagov.co.uk'                   
    else
      email_address = case action.request_type
      when Action::PUBLISHED then "team@alphagov.co.uk, freds@alphagov.co.uk"
      when Action::REVIEW_REQUESTED then "eds@alphagov.co.uk, seo@alphagov.co.uk, freds@alphagov.co.uk"
      else "eds@alphagov.co.uk, freds@alphagov.co.uk"
      end
    end                                           
    
    mail(:to => email_address,
         :subject => "[PUBLISHER] #{@action.friendly_description}") 
  end
  
  def request_fact_check(edition, details)
    @edition = edition
    fact_check_address = edition.fact_check_email_address 
    mail(:to => details[:email_addresses], :reply_to => fact_check_address, 
      :from => "Beta Editorial Team <#{fact_check_address}>", 
      :subject => "[FACT CHECK REQUESTED] #{edition.title}") do |format|
     format.text { render :text => details[:customised_message] }
   end
         
  end
  
end
