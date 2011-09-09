# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "winston@alphagov.co.uk"
  
  def make_noise(guide,action)
    @guide = guide
    @action = action
    
    email_address = case action.request_type
    when Action::PUBLISHED then "team@alphagov.co.uk"
    when Action::REVIEW_REQUESTED then "eds@alphagov.co.uk, seo@alphagov.co.uk"
    else "eds@alphagov.co.uk"
    end

    mail(:to => email_address,
         :subject => "[PUBLISHER] #{@action.friendly_description}: #{@action.edition.title}")
  end
  
end