source 'https://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'gds-api-adapters', '0.2.2'
if ENV['BUNDLE_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 1.2.0'
end

gem 'gds-warmup-controller'

gem 'rails', '3.2.8'
gem 'aws-ses', require: 'aws/ses'

gem 'erubis'
gem 'plek', '0.1.24'
gem 'gelf'
gem 'graylog2_exceptions'
gem 'rest-client'

gem 'null_logger'
gem 'daemonette', git: 'git@github.com:alphagov/daemonette.git'

gem 'rest-client'
gem "colorize", "~> 0.5.8"

gem 'inherited_resources'
gem 'formtastic', git: 'git://github.com/justinfrench/formtastic.git', branch: '2.1-stable'
gem 'formtastic-bootstrap', git: 'git://github.com/cgunther/formtastic-bootstrap.git', branch: 'bootstrap-2'
gem 'has_scope'
gem 'kaminari', '0.13.0'
gem 'lograge'

if ENV['CONTENT_MODELS_DEV']
  gem "govuk_content_models", :path => '../govuk_content_models'
else
  gem "govuk_content_models", "0.7.0"
end

gem 'mongo', '1.6.2'  # Locking this down to avoid a replica set bug

if ENV['CDN_DEV']
  gem 'cdn_helpers', path: '../cdn_helpers'
else
  gem 'cdn_helpers', '0.9'
end

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', path: '../govspeak'
else
  gem 'govspeak', '~> 0.8.15'
end

gem 'exception_notification', '~> 2.4.1', require: 'exception_notifier'
gem 'lockfile'
gem 'newrelic_rpm'
gem 'statsd-ruby', '1.0.0'
gem 'whenever'

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

  gem 'cucumber-rails', require: false

  gem 'capybara', '~> 1.0.0'
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
