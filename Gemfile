source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', :path => '../gds-sso'
else
  gem 'gds-sso', '~> 0.5.2'
end

gem 'gds-warmup-controller'

group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'rails', '3.1.3'
gem 'aws-ses', :require => 'aws/ses'

gem "mongoid", "~> 2.3"
gem "mongo", "1.5.2"
gem "bson_ext", "1.5.2"
gem "bson", "1.5.2"
gem 'erubis'
gem 'plek', '~> 0'
gem 'gelf'
gem 'graylog2_exceptions'
gem 'rest-client'
gem 'differ'

if ENV['MARPLES_DEV']
  gem 'marples', :path => '../marples'
else
  gem 'marples', '~> 1'
end

gem 'null_logger'
gem 'rummageable'
gem 'daemonette', :git => 'git@github.com:alphagov/daemonette.git'
gem 'gds-api-adapters', '~> 0.0.23'

gem 'rest-client'

gem "colorize", "~> 0.5.8"

gem 'inherited_resources'
gem 'formtastic', git: 'git://github.com/justinfrench/formtastic.git', branch: '2.1-stable'
gem 'formtastic-bootstrap', git: 'git://github.com/cgunther/formtastic-bootstrap.git', branch: 'bootstrap-2'
gem 'has_scope'
gem 'stomp', '1.1.9'
gem 'null_logger'
gem 'router-client', '2.0.3', require: 'router/client'

if ENV['CDN_DEV']
  gem 'cdn_helpers', :path => '../cdn_helpers'
else
  gem 'cdn_helpers', '0.9'
end

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', :path => '../govspeak'
else
  gem 'govspeak', '~> 0.8.7'
end

gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'
gem 'state_machine'

gem 'lockfile'
gem 'whenever'
gem 'newrelic_rpm'

group :assets do
  gem "therubyracer", "~> 0.9.4"
  gem 'uglifier'
end

group :development do
  gem 'passenger'
  if ENV['RUBY_DEBUG']
    gem 'ruby-debug19'
  end
end

group :test do
  gem 'test-unit'
  gem 'shoulda'
  gem 'database_cleaner'

  gem 'cucumber-rails', :require => false

  gem 'capybara', '~> 1.0.0'
  gem "capybara-webkit"
  gem 'launchy'

  gem 'webmock'
  gem 'mocha', :require => false
  gem 'factory_girl_rails'
  gem 'faker'

  gem "timecop"

  gem 'simplecov', '0.4.2'
  gem 'simplecov-rcov'
  gem 'ci_reporter'
end
