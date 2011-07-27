# encoding: utf-8

class NoisyWorkflow < ActionMailer::Base
  default :from => "winston@alphagov.co.uk"
  
  def make_noise(guide,action)
    @guide = guide
    @action = action
    mail(:to => "eds@alphagov.co.uk",
         :subject => "[GUIDES/ANSWERS] " + @action.friendly_description)
  end
end
