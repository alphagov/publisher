source 'https://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'aws-ses', require: 'aws/ses'
gem 'colorize', "~> 0.5.8"

if ENV['BUNDLE_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 1.2.0'
end
if ENV['CONTENT_MODELS_DEV']
  gem "govuk_content_models", :path => '../govuk_content_models'
else
  gem "govuk_content_models", "1.12.1"
end

gem 'erubis'
gem 'exception_notification', '~> 2.4.1', require: 'exception_notifier'
gem 'formtastic', git: 'https://github.com/justinfrench/formtastic.git', branch: '2.1-stable'
gem 'formtastic-bootstrap', git: 'https://github.com/cgunther/formtastic-bootstrap.git', branch: 'bootstrap-2'
gem 'gds-api-adapters', '1.8.0'
gem 'gds-warmup-controller'
gem 'gelf'
if ENV['GOVSPEAK_DEV']
  gem 'govspeak', path: '../govspeak'
else
  gem 'govspeak', '1.2.0'
end
gem 'graylog2_exceptions'
gem 'has_scope'
gem 'inherited_resources'
gem 'kaminari', '0.13.0'
gem 'lockfile'
gem 'lograge'
gem 'mongo', '1.6.2'  # Locking this down to avoid a replica set bug
gem 'newrelic_rpm'
gem 'null_logger'
gem 'plek', '0.1.24'
gem 'rails', '3.2.8'
gem 'rest-client'
gem 'rest-client'
gem 'reverse_markdown'
gem 'statsd-ruby', '1.0.0'
gem 'whenever'

gem 'jquery-rails'
gem 'less-rails-bootstrap'

group :assets do
  gem "therubyracer", "~> 0.9.4"
  gem 'uglifier'
end

group :development do
  gem 'passenger'
end

group :test do
  gem 'test-unit'
  gem 'shoulda'
  gem 'database_cleaner'

  gem 'capybara', '~> 1.1.0'
  gem "capybara-webkit"
  gem 'launchy'

  gem 'webmock'
  gem 'mocha', require: false
  gem 'factory_girl_rails'
  gem 'faker'

  gem "timecop"

  gem 'simplecov', '~> 0.6.4', :require => false
  gem 'simplecov-rcov', '~> 0.2.3', :require => false
  gem 'ci_reporter'
end
