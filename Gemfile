source "https://rubygems.org"

gem "rails", "6.0.3.2"

gem "bootstrap-kaminari-views"
gem "diffy"
gem "erubis"
gem "formtastic"
gem "formtastic-bootstrap"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "govuk_sidekiq"
gem "has_scope"
gem "inherited_resources"
gem "jquery-ui-rails"
gem "kaminari"
gem "kaminari-mongoid"
gem "mail-notify"
gem "mlanett-redis-lock" # Only used in some importers
gem "momentjs-rails"
gem "mongo"
gem "mongoid"
gem "mongoid-sadstory"
gem "mousetrap-rails"
gem "nested_form", git: "https://github.com/alphagov/nested_form.git", branch: "add-wrapper-class"
gem "null_logger"
gem "plek"
gem "rails_autolink"
gem "rest-client", require: false # Only used in some importers
gem "retriable", require: false # Only used in some importers
gem "reverse_markdown", require: false # Only used in some importers
gem "sass-rails"
gem "select2-rails", "3.5.9.1" # Updating this will mean updating the styling as 4 & > have a new approach to class names.
gem "selectize-rails"
gem "state_machines"
gem "state_machines-mongoid"
gem "strip_attributes"
gem "uglifier"
gem "whenever", require: false

group :test do
  gem "ci_reporter_minitest"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "govuk-content-schema-test-helpers"
  gem "govuk_test"
  gem "minitest-reporters"
  gem "mocha"
  gem "rails-controller-testing"
  gem "shoulda"
  gem "simplecov", require: false
  gem "simplecov-rcov", require: false
  gem "timecop"
  gem "webdrivers"
  gem "webmock"
end

group :development do
  gem "state_machines-graphviz"
end

group :development, :test do
  gem "jasmine"
  gem "jasmine-core"
  gem "jasmine_selenium_runner", require: false
  gem "pry-byebug"
  gem "rack"
  gem "rubocop-govuk"
end
