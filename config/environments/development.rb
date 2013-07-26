Publisher::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.action_mailer.default_url_options = { :host => "www.#{ENV['GOVUK_APP_DOMAIN']}" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :user_name => ENV["MANDRILL_USERNAME"],
    :password => ENV["MANDRILL_PASSWORD"],
    :domain => "theodi.org",
    :address => "smtp.mandrillapp.com",
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
  }

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
end
