# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "Winston (GOV.UK Publisher) <winston@alphagov.co.uk>"

  EMAIL_GROUPS = {
    'team' => 'govuk-team@digital.cabinet-office.gov.uk',
    'dev' => 'govuk-dev@digital.cabinet-office.gov.uk',
    'freds' => 'freds@alphagov.co.uk',
    'seo' => 'seo@alphagov.co.uk',
    'eds' => 'govuk-content-designers@digital.cabinet-office.gov.uk',
    'biz' => 'publisher-alerts-business@digital.cabinet-office.gov.uk'
  }

  def make_noise(action)
    @action = action

    case Plek.current.environment
    when 'preview'
      email_address = EMAIL_GROUPS['dev']
    else
      if action.edition.business_proposition
        subject = "[PUBLISHER]-BUSINESS #{@action.friendly_description}"
        if action.request_type == Action::PUBLISH
          email_address = "#{EMAIL_GROUPS['team']}, #{EMAIL_GROUPS['biz']}"
        else
          email_address = "#{EMAIL_GROUPS['biz']}"
        end
      else
        subject = "[PUBLISHER] #{@action.friendly_description}"
        email_address = case action.request_type
        when Action::PUBLISH then "#{EMAIL_GROUPS['team']}, #{EMAIL_GROUPS['freds']}"
        when Action::REQUEST_REVIEW then "#{EMAIL_GROUPS['eds']}, #{EMAIL_GROUPS['seo']}, #{EMAIL_GROUPS['freds']}"
        else "#{EMAIL_GROUPS['eds']}, #{EMAIL_GROUPS['freds']}"
        end
      end
    end
    
    mail(:to => email_address,
         :subject => subject)
  end

  def request_fact_check(action)
    @edition = action.edition
    fact_check_address = @edition.fact_check_email_address
    mail(:to => action.email_addresses, :reply_to => fact_check_address,
      :from => "Beta Editorial Team <#{fact_check_address}>",
      :subject => "[FACT CHECK REQUESTED] #{@edition.title}") do |format|
     format.text { render :text => action.customised_message }
   end

  end

  def report_errors(error_list)
    @errors = error_list
    mail(:to => EMAIL_GROUPS['dev'], :subject => 'Errors in fact check email processing')
  end

end
