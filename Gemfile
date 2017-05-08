source 'https://rubygems.org'

gem 'airbrake', git: 'https://github.com/alphagov/airbrake.git', branch: 'silence-dep-warnings-for-rails-5'
gem 'bootstrap-kaminari-views', '0.0.3'
gem 'diffy', '3.0.6'
gem 'erubis'
gem 'formtastic', '2.3.0'
gem 'formtastic-bootstrap', '3.0.0'
gem 'gds-sso', '~> 13.2'
gem 'gds-api-adapters', '~> 46.0.0'
gem 'govspeak', '~> 3.4.0'
gem 'govuk_admin_template', '4.3.0'
if ENV["API_DEV"]
  gem "govuk_content_models", path: "../govuk_content_models"
else
  gem 'govuk_content_models', "45.0.0"
end
gem 'govuk_sidekiq', '1.0.3'
gem 'has_scope'
gem 'inherited_resources'
gem 'jquery-ui-rails', '~> 5.0.3'
gem 'kaminari', '0.17.0'
gem 'kaminari-mongoid', '1.0.1'
gem 'logstasher', '0.4.8'
gem 'mlanett-redis-lock', '0.2.2' # Only used in some importers
gem 'momentjs-rails', '2.8.3'
gem "mongoid_rails_migrations", "1.0.0"
gem "mongoid-sadstory"
gem 'mousetrap-rails', '1.4.6'
gem "nested_form", git: 'https://github.com/alphagov/nested_form.git', branch: 'add-wrapper-class'
gem 'null_logger'
gem 'plek', '1.9.0'
gem 'rails', '5.0.2'
gem 'rails_autolink', '1.1.6'
gem 'rest-client', require: false # Only used in some importers
gem 'retriable', require: false # Only used in some importers
gem 'reverse_markdown', '0.3.0', require: false # Only used in some importers
gem 'sass-rails', '~> 5.0'
gem 'select2-rails', '3.5.9.1'
gem 'selectize-rails', '0.12.1'
gem 'statsd-ruby', '~> 1.1.0', require: false
gem 'uglifier', '2.7.2'
gem 'unicorn', '4.3.1'
gem 'whenever', require: false

group :test do
  gem 'capybara', '2.12.1'
  gem 'capybara-screenshot'
  gem 'ci_reporter_minitest', '1.0.0'
  gem 'database_cleaner', '1.5.3'
  gem 'factory_girl_rails'
  gem 'govuk-content-schema-test-helpers', '~> 1.4'
  gem 'launchy', '2.4.3'
  gem 'maxitest', '~> 2.4'
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'mocha', '1.2.1'
  gem 'poltergeist', '1.13.0'
  gem 'rails-perftest'
  gem 'rails-controller-testing'
  gem 'ruby-prof'
  gem 'shoulda', '3.5.0'
  gem 'simplecov', '~> 0.6.4', require: false
  gem 'simplecov-rcov', '~> 0.2.3', require: false
  gem "timecop", '0.8.0'
  gem 'webmock', '~> 1.22'
end

group :development, :test do
  gem 'ci_reporter_rspec'
  gem 'govuk-lint', '~> 0.7'
  gem 'jasmine', '2.5.2'
  gem 'jasmine-core', '2.5.2'
  gem 'rack', '2.0.3'
  gem 'pry-byebug'
end
