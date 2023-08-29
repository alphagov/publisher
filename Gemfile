source "https://rubygems.org"

gem "rails", "7.0.7.2"

gem "aws-sdk-s3", "~> 1"
gem "bootsnap", require: false
gem "bootstrap-kaminari-views"
gem "diffy"
gem "erubis"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "govuk_sidekiq"
gem "has_scope"
gem "html2text"
gem "inherited_resources"
gem "jquery-ui-rails"
gem "kaminari"
gem "kaminari-mongoid"
gem "mail-notify"
gem "mlanett-redis-lock"
gem "momentjs-rails"
gem "mongo"
gem "mongoid"
gem "mongoid-sadstory"
gem "mousetrap-rails"
gem "nested_form", git: "https://github.com/alphagov/nested_form.git", branch: "add-wrapper-class"
gem "null_logger"
gem "plek"
gem "rails_autolink"
gem "rest-client", require: false
gem "sassc-rails"
gem "select2-rails", "~> 3.5.9" # Updating this will mean updating the styling as 4 & > have a new approach to class names.
gem "sentry-sidekiq"
gem "sprockets-rails"
gem "state_machines"
gem "state_machines-mongoid"
gem "strip_attributes"
gem "uglifier"
gem "whenever", require: false

group :test do
  gem "capybara-select-2"
  gem "ci_reporter_minitest"
  gem "climate_control"
  gem "database_cleaner-mongoid"
  gem "factory_bot_rails"
  gem "govuk_schemas"
  gem "launchy"
  gem "minitest-reporters"
  gem "mocha"
  gem "rails-controller-testing"
  gem "shoulda"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end

group :development do
  gem "state_machines-graphviz"
end

group :development, :test do
  gem "govuk_test"
  gem "pry-byebug"
  gem "rack"
  gem "rubocop-govuk"
end
