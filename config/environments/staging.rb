require File.expand_path('production.rb', File.dirname(__FILE__))

Guides::Application.configure do
  config.action_controller.asset_host = 'staging.alphagov.co.uk:8080'
  config.action_mailer.smtp_settings = {:enable_starttls_auto => false}
end