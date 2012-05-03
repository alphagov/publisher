require File.expand_path('production.rb', File.dirname(__FILE__))

Publisher::Application.configure do
  config.action_mailer.smtp_settings = {:enable_starttls_auto => false}

  config.action_mailer.default_url_options = { :host => "guides.staging.alphagov.co.uk:8080" }
end