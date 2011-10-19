require File.expand_path('production.rb', File.dirname(__FILE__))

Publisher::Application.configure do
  config.action_controller.asset_host = 'staging.alphagov.co.uk:8080'
  config.action_mailer.smtp_settings = {:enable_starttls_auto => false}

  config.middleware.delete Slimmer::App
  config.middleware.use Slimmer::App, :template_host => "/data/vhost/static.#{Rails.env}.alphagov.co.uk/current/public/templates"
  
  config.action_mailer.default_url_options = { :host => "guides.staging.alphagov.co.uk:8080" }
end