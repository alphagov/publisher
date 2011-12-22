source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

if ENV['BUNDLE_DEV']
  gem 'gds-sso', :path => '../gds-sso'
else
  gem 'warden', '1.0.6'
  gem 'gds-sso', :git => 'git@github.com:alphagov/gds-sso.git'
end

group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'rails', '3.1.3'

gem "mongoid", "~> 2.3"
gem "mongo", "1.5.2"
gem "bson_ext", "1.5.2"
gem "bson", "1.5.2"
gem 'erubis'
gem 'plek', '~> 0'
gem 'pethau', '0.0.3'

if ENV['MARPLES_DEV']
  gem 'marples', :path => '../marples'
else
  gem 'marples', '~> 1'
end

gem 'null_logger'
gem 'rummageable', :git => 'git@github.com:alphagov/rummageable.git'
gem 'daemonette', :git => 'git@github.com:alphagov/daemonette.git'
gem 'gds-api-adapters', '0.0.12'

gem 'rest-client'

gem "colorize", "~> 0.5.8"

gem 'inherited_resources'
gem 'formtastic', '~> 2.0.0'
gem 'has_scope'
gem 'stomp', '1.1.9'
gem 'null_logger'
gem 'router-client', '2.0.3', require: 'router/client'

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', '1.1.12'
end

if ENV['CDN_DEV']
  gem 'cdn_helpers', :path => '../cdn_helpers'
else
  gem 'cdn_helpers', '0.9'
end

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', :path => '../govspeak'
else
  gem 'govspeak', '0.8.4'
end

gem 'exception_notification', '~> 2.4.1', :require => 'exception_notifier'
gem 'state_machine'

gem 'lockfile'
gem 'whenever'

group :development do
  gem 'passenger'
  if ENV['RUBY_DEBUG']
    gem 'ruby-debug19'
  end
end

group :test do
  gem 'fabrication'
  gem "timecop"
  gem 'capybara', '~> 1.0.0'
  gem "capybara-webkit"
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'mocha', :require => false
  gem 'simplecov', '0.4.2'
  gem 'simplecov-rcov'
  gem 'ci_reporter'
  gem 'webmock'
  gem 'test-unit'
  gem 'launchy'
  gem 'factory_girl_rails'
  gem 'faker'
end
