# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "winston@alphagov.co.uk"
  
  def make_noise(guide,action)
    @guide = guide
    @action = action
    
    if action.request_type == Action::PUBLISHED
        email_address = "team@alphagov.co.uk"
    else
        email_address = "eds@alphagov.co.uk"
    end

    mail(:to => email_address,
         :subject => "[PUBLISHER] " + @action.friendly_description)
  end
  
end