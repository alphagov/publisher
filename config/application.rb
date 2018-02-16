require_relative 'boot'

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Publisher
  class Application < Rails::Application
    # Configuration object for the fact check email fetch script
    # See `script/mail_fetcher`
    attr_accessor :mail_fetcher_config

    # Configuration object for fact check address construction and parsing
    attr_accessor :fact_check_config

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.prefix = '/assets'

    # Custom directories with classes and modules you want to be autoloadable.
    config.eager_load_paths += %W(#{config.root}/lib #{config.root}/app/presenters #{config.root}/app/decorators)

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :erb # this could be :haml or whatever
      g.test_framework :test_unit, fixture: false # this could be :rpsec or whatever
    end

    config.action_dispatch.rack_cache = nil

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Enforce locale restriction to silence deprecation warnings; this will be
    # the default in future Rails versions.
    config.i18n.enforce_available_locales = true

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.jwt_auth_secret = ENV['JWT_AUTH_SECRET']
  end
end

require 'open-uri'
require 'builder'
