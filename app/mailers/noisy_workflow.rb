# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "Winston (Gov.UK Publisher) <winston@alphagov.co.uk>"
  
  EMAIL_GROUPS = {
    'team' => 'govuk-team@digital.cabinet-office.gov.uk',
    'dev' => 'govuk-dev@digital.cabinet-office.gov.uk',
    'freds' => 'freds@alphagov.co.uk',
    'seo' => 'seo@alphagov.co.uk',
    'eds' => 'govuk-content-designers@digital.cabinet-office.gov.uk'
  }

  def make_noise(publication, action)
    @publication = publication
    @action = action
                                                  
    case Plek.current.environment
    when 'preview' 
      email_address = EMAIL_GROUPS['dev']
    else
      email_address = case action.request_type
      when Action::PUBLISH then "#{EMAIL_GROUPS['team']}, #{EMAIL_GROUPS['freds']}"
      when Action::REQUEST_REVIEW then "#{EMAIL_GROUPS['eds']}, #{EMAIL_GROUPS['seo']}, #{EMAIL_GROUPS['freds']}"
      else "#{EMAIL_GROUPS['eds']}, #{EMAIL_GROUPS['freds']}"
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
  
  def report_errors(error_list)
    @errors = error_list
    mail(:to => EMAIL_GROUPS['dev'], :subject => 'Errors in fact check email processing')
  end
  
end
