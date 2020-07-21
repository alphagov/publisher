source "https://rubygems.org"

gem "bootstrap-kaminari-views", "0.0.5"
gem "diffy", "3.3.0"
gem "erubis"
gem "formtastic", "3.1.5"
gem "formtastic-bootstrap", "3.1.1"
gem "gds-api-adapters", "~> 67.0"
gem "gds-sso", "~> 15.0"
gem "govspeak", "~> 6.5.4"
gem "govuk_admin_template", "~> 6.7"
gem "govuk_app_config", "~> 2.2.1"
gem "govuk_sidekiq", "~> 3.0.5"
gem "has_scope"
gem "inherited_resources"
gem "jquery-ui-rails", "~> 6.0"
gem "kaminari", "~> 1.2"
gem "kaminari-mongoid", "1.0.1"
gem "mail-notify"
gem "mlanett-redis-lock", "0.2.7" # Only used in some importers
gem "momentjs-rails", "2.20.1"
gem "mongo", "~> 2.12.1"
gem "mongoid", "~> 6.3"
gem "mongoid-sadstory"
gem "mousetrap-rails", "1.4.6"
gem "nested_form", git: "https://github.com/alphagov/nested_form.git", branch: "add-wrapper-class"
gem "null_logger"
gem "plek", "4.0.0"
gem "rails", "~> 5.2"
gem "rails_autolink", "1.1.6"
gem "rest-client", require: false # Only used in some importers
gem "retriable", require: false # Only used in some importers
gem "reverse_markdown", "2.0.0", require: false # Only used in some importers
gem "sass-rails", "~> 5.0"
gem "select2-rails", "3.5.9.1" # Updating this will mean updating the styling as 4 & > have a new approach to class names.
gem "selectize-rails", "0.12.6"
gem "state_machines", "~> 0.4"
gem "state_machines-mongoid", "~> 0.1"
gem "strip_attributes", "~> 1.11"
gem "uglifier", "4.2.0"
gem "whenever", require: false

group :test do
  gem "ci_reporter_minitest", "1.0.0"
  gem "database_cleaner", "1.8.5"
  gem "factory_bot_rails"
  gem "govuk-content-schema-test-helpers", "~> 1.6"
  gem "govuk_test"
  gem "minitest-reporters"
  gem "mocha", "1.9.0"
  gem "rails-controller-testing"
  gem "shoulda", "4.0.0"
  gem "simplecov", "~> 0.18.5", require: false
  gem "simplecov-rcov", "~> 0.2.3", require: false
  gem "timecop", "0.9.1"
  gem "webmock", "~> 3.8.3"
end

group :development do
  gem "state_machines-graphviz"
end

group :development, :test do
  gem "jasmine", "~> 3.5.1"
  gem "jasmine-core", "~> 3.5.0"
  gem "pry-byebug"
  gem "rack", "2.2.3"
  gem "rubocop-govuk"
end
