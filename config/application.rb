require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

require "open-uri"
require "builder"
require_relative "../app/middleware/maintenance_mode"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Publisher
  class Application < Rails::Application
    # Before filter for Flipflop dashboard. Replace with a lambda or method name
    # defined in ApplicationController to implement access control.
    config.flipflop.dashboard_access_filter = nil

    # By default, when set to `nil`, strategy loading errors are suppressed in test
    # mode. Set to `true` to always raise errors, or `false` to always warn.
    config.flipflop.raise_strategy_errors = nil

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    # Due to how we initialize state_count_reporter we need to disable a new
    # optimisation put in place in Rails 7.1.
    # See: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloaded-paths-are-no-longer-in-$load-path
    config.add_autoload_paths_to_load_path = true

    # Configuration object for fact check address construction and parsing
    attr_accessor :fact_check_config

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = "1.0"

    # Set asset path to be application specific so that we can put all GOV.UK
    # assets into an S3 bucket and distinguish app by path.
    config.assets.prefix = "/assets/publisher"

    # allow overriding the asset host with an environment variable, useful for
    # when router is proxying to this app but asset proxying isn't set up.
    config.asset_host = ENV.fetch("ASSET_HOST", nil)

    config.action_mailer.notify_settings = {
      api_key: ENV["GOVUK_NOTIFY_API_KEY"] || "fake-test-api-key",
    }

    config.generators do |g|
      g.orm :active_record
      g.template_engine :erb # this could be :haml or whatever
      g.test_framework :test_unit, fixture: false # this could be :rpsec or whatever
    end

    config.action_dispatch.rack_cache = nil

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default set by govuk_app_config is London.
    config.govuk_time_zone = "London"

    # Enforce locale restriction to silence deprecation warnings; this will be
    # the default in future Rails versions.
    config.i18n.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.jwt_auth_secret = ENV["JWT_AUTH_SECRET"]

    # Using a sass css compressor causes a scss file to be processed twice
    # (once to build, once to compress) which breaks the usage of "unquote"
    # to use CSS that has same function names as SCSS such as max.
    # https://github.com/alphagov/govuk-frontend/issues/1350
    config.assets.css_compressor = nil

    # Enable per-form CSRF tokens. Previous versions had false.
    Rails.application.config.action_controller.per_form_csrf_tokens = true

    # Enable origin-checking CSRF mitigation. Previous versions had false.
    Rails.application.config.action_controller.forgery_protection_origin_check = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths << Rails.root.join("app/middleware")
    config.middleware.use MaintenanceMode

    ###
    # Adds image/webp to the list of content types Active Storage considers as an image
    # Prevents automatic conversion to a fallback PNG, and assumes clients support WebP, as they support gif, jpeg, and png.
    # This is possible due to broad browser support for WebP, but older browsers and email clients may still not support
    # WebP. Requires imagemagick/libvips built with WebP support.
    #++
    # Rails.application.config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]

    ###
    # Enable validation of migration timestamps. When set, an ActiveRecord::InvalidMigrationTimestampError
    # will be raised if the timestamp prefix for a migration is more than a day ahead of the timestamp
    # associated with the current time. This is done to prevent forward-dating of migration files, which can
    # impact migration generation and other migration commands.
    #
    # Applications with existing timestamped migrations that do not adhere to the
    # expected format can disable validation by setting this config to `false`.
    #++
    Rails.application.config.active_record.validate_migration_timestamps = false

    ###
    # Controls whether the PostgresqlAdapter should decode dates automatically with manual queries.
    #
    # Example:
    #   ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.select_value("select '2024-01-01'::date") #=> Date
    #
    # This query used to return a `String`.
    #++
    Rails.application.config.active_record.postgresql_adapter_decode_dates = false

    ###
    # Enables YJIT as of Ruby 3.3, to bring sizeable performance improvements. If you are
    # deploying to a memory constrained environment you may want to set this to `false`.
    #++
    Rails.application.config.yjit = false
  end
end
